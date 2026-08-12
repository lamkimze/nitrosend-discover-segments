module Segmentation
  class MembershipUpdater
    def self.call(result:, analysis:, mode: :full, pending_contact_ids: [])
      new(
        result: result,
        analysis: analysis,
        mode: mode.to_sym,
        pending_contact_ids: pending_contact_ids
      ).call
    end

    def initialize(result:, analysis:, mode:, pending_contact_ids:)
      @result = result
      @analysis = analysis
      @mode = mode
      @pending_contact_ids = pending_contact_ids.map(&:to_i).to_set
      @existing_slugs = Segment.active.pluck(:slug).to_set
    end

    def call
      ActiveRecord::Base.transaction do
        @result[:segments].map do |payload|
          slug = payload[:name].parameterize
          is_new_segment = !@existing_slugs.include?(slug)

          segment = Segment.find_or_initialize_by(slug: slug)
          segment.assign_attributes(
            name: payload[:name],
            description: payload[:description],
            source: "ai",
            status: "active",
            confidence_score: payload[:confidence],
            evidence: payload[:evidence]
          )
          segment.save!

          if @mode == :incremental
            additive_sync!(segment, payload[:members], new_segment: is_new_segment)
          else
            replace_sync!(segment, payload[:members])
          end

          @existing_slugs << segment.slug
          segment.refresh_contact_count!
          segment
        end
      end
    end

    private

    # Incremental rules:
    # - Existing segments: only add/update memberships for newly imported (pending) contacts.
    # - New segments: may include old contacts as well as new ones.
    # - Never remove existing memberships.
    def additive_sync!(segment, members, new_segment:)
      members.each do |member|
        contact_id = member[:contact_id]
        next unless Contact.exists?(id: contact_id)

        unless new_segment || @pending_contact_ids.include?(contact_id)
          next
        end

        membership = segment.segment_memberships.find_or_initialize_by(contact_id: contact_id)
        membership.score = member[:score]
        membership.reason = member[:reason]
        membership.save!
      end
    end

    # Full refresh: replace memberships from latest behaviour (additions and removals).
    def replace_sync!(segment, members)
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
