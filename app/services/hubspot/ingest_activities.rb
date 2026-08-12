module Hubspot
  # Accepts HubSpot-shaped activity payloads and stores them as Event rows.
  # In production this would be fed by CRM / Events API sync; here it makes
  # the demo architecture explicit.
  #
  # Example payload (matches the take-home brief):
  #   {
  #     "contactId" => "12345",
  #     "email" => "john@example.com",
  #     "activities" => [
  #       { "type" => "PAGE_VIEW", "url" => "/japan-trips", "timestamp" => "..." }
  #     ],
  #     "emailEvents" => [
  #       { "type" => "OPEN", "campaign" => "Japan Travel Deals" },
  #       { "type" => "CLICK", "url" => "https://example.com/japan-packages" }
  #     ]
  #   }
  class IngestActivities
    TYPE_MAP = {
      "PAGE_VIEW" => "page_view",
      "EMAIL_OPEN" => "email_open",
      "OPEN" => "email_open",
      "EMAIL_CLICK" => "email_click",
      "CLICK" => "email_click",
      "FORM_SUBMISSION" => "form_submission",
      "CTA_CLICK" => "cta_click",
      "PURCHASE" => "purchase",
      "DEAL_WON" => "purchase"
    }.freeze

    def self.call(contact:, activities: [], email_events: [])
      new(contact: contact, activities: activities, email_events: email_events).call
    end

    def initialize(contact:, activities:, email_events:)
      @contact = contact
      @activities = Array(activities)
      @email_events = Array(email_events)
    end

    def call
      created = 0
      (@activities + @email_events).each do |raw|
        event = ingest_one(raw)
        created += 1 if event
      end
      created
    end

    private

    def ingest_one(raw)
      payload = raw.respond_to?(:with_indifferent_access) ? raw.with_indifferent_access : raw.to_h.with_indifferent_access
      type = TYPE_MAP[payload[:type].to_s.upcase]
      return if type.blank?

      occurred_at = parse_time(payload[:timestamp]) || Time.current
      metadata = {}
      metadata["url"] = payload[:url] if payload[:url].present?
      metadata["title"] = payload[:title] if payload[:title].present?
      metadata["campaign"] = payload[:campaign] if payload[:campaign].present?
      metadata["form"] = payload[:form] if payload[:form].present?
      metadata["cta"] = payload[:cta] if payload[:cta].present?
      metadata["destination"] = payload[:destination] if payload[:destination].present?
      metadata["style"] = payload[:style] if payload[:style].present?
      metadata["value"] = payload[:value] if payload[:value].present?

      @contact.events.create!(
        event_type: type,
        occurred_at: occurred_at,
        metadata: metadata
      )
    end

    def parse_time(value)
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone) || value.is_a?(DateTime)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
