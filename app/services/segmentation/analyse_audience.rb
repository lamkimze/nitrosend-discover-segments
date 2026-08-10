module Segmentation
  class AnalyseAudience
    Result = Struct.new(:analysis, :segments, keyword_init: true)

    def self.call(analysis:)
      new(analysis: analysis).call
    end

    def initialize(analysis:)
      @analysis = analysis
    end

    def call
      @analysis.mark_processing!
      @analysis.update!(contact_count: Contact.count, model: provider_name)

      profiles = Contact.includes(:events).map { |c| BuildCustomerProfile.call(c) }
      raw = provider.analyse(profiles)
      validated = validate!(raw)

      before_counts = Segment.active.index_by(&:slug).transform_values(&:contact_count)
      segments = MembershipUpdater.call(result: validated, analysis: @analysis)
      after = Segment.active.index_by(&:slug)

      summary = build_summary(before_counts, after)
      @analysis.mark_completed!(segments_found: segments.size, summary: summary)

      Result.new(analysis: @analysis, segments: segments)
    rescue StandardError => e
      @analysis.mark_failed!(e.message)
      raise
    end

    private

    def provider
      case ENV.fetch("SEGMENTATION_PROVIDER", "demo")
      when "openai" then Providers::OpenAi.new
      else Providers::Demo.new
      end
    end

    def provider_name
      ENV.fetch("SEGMENTATION_PROVIDER", "demo")
    end

    def validate!(raw)
      raise "Provider returned no payload" if raw.blank?
      raise "Provider payload missing segments" unless raw[:segments] || raw["segments"]

      segments = raw[:segments] || raw["segments"]
      raise "No segments discovered" if segments.blank?

      segments.each do |segment|
        name = segment[:name] || segment["name"]
        members = segment[:members] || segment["members"] || segment[:contacts] || segment["contacts"]
        raise "Segment missing name" if name.blank?
        raise "Segment #{name} missing members" if members.blank?
      end

      { segments: segments.map { |s| normalize_segment(s) } }
    end

    def normalize_segment(segment)
      {
        name: segment[:name] || segment["name"],
        description: segment[:description] || segment["description"],
        confidence: (segment[:confidence] || segment["confidence"] || 0).to_f,
        evidence: Array(segment[:evidence] || segment["evidence"]),
        members: Array(segment[:members] || segment["members"] || segment[:contacts] || segment["contacts"]).map do |m|
          {
            contact_id: (m[:contact_id] || m["contact_id"]).to_i,
            score: (m[:score] || m["score"] || 0).to_f,
            reason: m[:reason] || m["reason"]
          }
        end
      }
    end

    def build_summary(before_counts, after)
      changes = after.map do |slug, segment|
        previous = before_counts[slug] || 0
        delta = segment.contact_count - previous
        { name: segment.name, previous: previous, current: segment.contact_count, delta: delta }
      end

      {
        added_memberships: changes.sum { |c| [ c[:delta], 0 ].max },
        removed_memberships: changes.sum { |c| [ -c[:delta], 0 ].max },
        segments: changes
      }
    end
  end
end
