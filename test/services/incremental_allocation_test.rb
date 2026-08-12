# frozen_string_literal: true

require "test_helper"

class IncrementalAllocationTest < ActiveSupport::TestCase
  setup do
    Contact.delete_all
    Event.delete_all
    SegmentMembership.delete_all
    Campaign.delete_all
    Segment.delete_all
    AiAnalysisRun.delete_all

    12.times do |i|
      c = Contact.create!(
        email: "base#{i}@example.com",
        first_name: "Base",
        last_name: "J#{i}",
        pending_allocation: false,
        source: "hubspot"
      )
      3.times { c.events.create!(event_type: "page_view", occurred_at: 1.day.ago, metadata: { "url" => "/japan-tours" }) }
      c.events.create!(event_type: "email_click", occurred_at: 1.day.ago, metadata: { "campaign" => "Japan Travel Deals" })
      c.events.create!(event_type: "purchase", occurred_at: 2.days.ago, metadata: { "destination" => "Japan", "style" => "mid", "value" => 2200 })
    end

    analysis = AiAnalysisRun.create!(status: "pending", mode: "full")
    Segmentation::AnalyseAudience.call(analysis: analysis)
    @japan = Segment.find_by!(name: "Japan Enthusiasts")
    @original_ids = @japan.contact_ids.sort
    @original_count = @japan.contact_count
  end

  test "incremental adds pending contacts without removing existing memberships" do
    imported = Contacts::Import.call(
      rows: Array.new(5) do |i|
        {
          email: "new#{i}@example.com",
          first_name: "New",
          last_name: "J#{i}",
          persona: "japan"
        }
      end
    )
    assert_equal 5, imported.created
    assert_equal 5, Contact.pending_allocation.count

    run = AiAnalysisRun.create!(status: "pending", mode: "incremental")
    Segmentation::AnalyseAudience.call(analysis: run)

    @japan.reload
    assert_operator @japan.contact_count, :>=, @original_count
    @original_ids.each do |id|
      assert @japan.contact_ids.include?(id), "existing contact #{id} must stay in Japan Enthusiasts"
    end

    new_ids = Contact.where("email LIKE ?", "new%@example.com").pluck(:id)
    assert new_ids.any? { |id| @japan.contact_ids.include?(id) }, "at least one imported japan contact should join"
    assert_equal 0, Contact.pending_allocation.count
    assert run.reload.completed?
    assert_equal "incremental", run.summary["mode"]
  end

  test "incremental refuses when nothing is pending" do
    run = AiAnalysisRun.create!(status: "pending", mode: "incremental")
    assert_raises(RuntimeError) { Segmentation::AnalyseAudience.call(analysis: run) }
    assert run.reload.failed?
  end

  test "full refresh can remove memberships when behaviour no longer matches" do
    outlier = Contact.create!(
      email: "outlier@example.com",
      first_name: "Out",
      last_name: "Lier",
      pending_allocation: false
    )
    @japan.segment_memberships.create!(contact: outlier, score: 0.9, reason: "manual for test")
    @japan.refresh_contact_count!

    run = AiAnalysisRun.create!(status: "pending", mode: "full")
    Segmentation::AnalyseAudience.call(analysis: run)

    @japan.reload
    refute @japan.contact_ids.include?(outlier.id)
  end
end
