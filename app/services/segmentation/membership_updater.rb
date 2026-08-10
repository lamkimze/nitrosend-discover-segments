module Segmentation
  class MembershipUpdater
    def self.call(result:, analysis:)
      new(result: result, analysis: analysis).call
    end

    def initialize(result:, analysis:)
      @result = result
      @analysis = analysis
    end

    def call
      ActiveRecord::Base.transaction do
        seen_slugs = []

        @result[:segments].map do |payload|
          segment = Segment.find_or_initialize_by(slug: payload[:name].parameterize)
          segment.assign_attributes(
            name: payload[:name],
            description: payload[:description],
            source: "ai",
            status: "active",
            confidence_score: payload[:confidence],
            evidence: payload[:evidence]
          )
          segment.save!

          seen_slugs << segment.slug
          sync_memberships!(segment, payload[:members])
          segment.refresh_contact_count!
          segment
        end.tap do
          # Keep historical AI segments that disappeared this run, but clear memberships
          # only for ones we replaced by slug. Leave untouched if not in result.
        end
      end
    end

    private

    def sync_memberships!(segment, members)
      keep_ids = []

      members.each do |member|
        contact = Contact.find_by(id: member[:contact_id])
        next unless contact

        membership = segment.segment_memberships.find_or_initialize_by(contact: contact)
        membership.score = member[:score]
        membership.reason = member[:reason]
        membership.save!
        keep_ids << membership.id
      end

      segment.segment_memberships.where.not(id: keep_ids).delete_all
    end
  end
end
