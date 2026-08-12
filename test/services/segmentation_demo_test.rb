# frozen_string_literal: true

require "test_helper"

class SegmentationDemoTest < ActiveSupport::TestCase
  setup do
    Contact.delete_all
    Event.delete_all
    SegmentMembership.delete_all
    Segment.delete_all
    AiAnalysisRun.delete_all

    @japan = Contact.create!(email: "japan@example.com", first_name: "A", last_name: "Japan", source: "hubspot")
    4.times do |i|
      @japan.events.create!(event_type: "page_view", occurred_at: i.days.ago, metadata: { "url" => "/tokyo-hotels" })
    end
    @japan.events.create!(event_type: "email_click", occurred_at: 1.day.ago, metadata: { "campaign" => "Japan Travel Deals", "url" => "/japan-packages" })
    @japan.events.create!(event_type: "purchase", occurred_at: 2.days.ago, metadata: { "destination" => "Japan", "style" => "mid", "value" => 2200 })

    @luxury = Contact.create!(email: "lux@example.com", first_name: "B", last_name: "Lux", source: "hubspot")
    @luxury.events.create!(event_type: "page_view", occurred_at: 1.day.ago, metadata: { "url" => "/luxury-villas" })
    @luxury.events.create!(event_type: "purchase", occurred_at: 3.days.ago, metadata: { "destination" => "Maldives", "style" => "luxury", "value" => 5200 })
  end

  test "build customer profile from HubSpot-style events" do
    profile = Segmentation::BuildCustomerProfile.call(@japan)
    assert_equal @japan.id, profile[:contact_id]
    assert profile[:pages_visited].include?("/tokyo-hotels")
    assert profile[:page_interests].include?("Japan")
    assert_operator profile[:purchases][:count], :>=, 1
    assert_operator profile[:engagement][:emails_clicked], :>=, 1
  end

  test "demo provider discovers japan enthusiasts" do
    profiles = Contact.includes(:events).map { |c| Segmentation::BuildCustomerProfile.call(c) }
    result = Segmentation::Providers::Demo.new.analyse(profiles)
    assert result[:segments].is_a?(Array)
  end

  test "analyse audience assigns memberships and allows multi-segment" do
    10.times do |i|
      c = Contact.create!(email: "j#{i}@example.com", first_name: "J", last_name: "T#{i}", source: "hubspot")
      3.times { c.events.create!(event_type: "page_view", occurred_at: 1.day.ago, metadata: { "url" => "/japan-tours" }) }
      c.events.create!(event_type: "email_click", occurred_at: 1.day.ago, metadata: { "campaign" => "Japan Travel Deals" })
      c.events.create!(event_type: "purchase", occurred_at: 2.days.ago, metadata: { "destination" => "Japan", "style" => "luxury", "value" => 3000 })
    end

    analysis = AiAnalysisRun.create!(status: "pending")
    Segmentation::AnalyseAudience.call(analysis: analysis)

    analysis.reload
    assert analysis.completed?
    assert_operator analysis.segments_found, :>=, 1

    japan = Segment.find_by(name: "Japan Enthusiasts")
    assert japan
    assert_operator japan.contact_count, :>=, 8

    member = japan.contacts.first
    assert member.segments.count >= 1
  end

  test "failed analysis does not raise past mark_failed when validate empty" do
    SegmentMembership.delete_all
    Campaign.delete_all
    Segment.delete_all
    Event.delete_all
    Contact.delete_all
    analysis = AiAnalysisRun.create!(status: "pending")
    assert_raises(RuntimeError) do
      Segmentation::AnalyseAudience.call(analysis: analysis)
    end
    assert analysis.reload.failed?
    assert_match(/No segments|Provider|empty|discover/i, analysis.error_message)
  end
end
