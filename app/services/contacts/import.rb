module Contacts
  # Imports contacts and attaches HubSpot-style behavioural events so
  # segmentation has signal. New rows are flagged pending_allocation.
  class Import
    Result = Struct.new(:created, :skipped, :pending_count, keyword_init: true)

    PERSONAS = %w[japan luxury budget engaged mixed].freeze

    def self.call(rows:, source: "hubspot")
      new(rows: rows, source: source).call
    end

    def self.sample_batch(count: 25)
      rng = Random.new
      firsts = %w[Kim Alex Jordan Sam Riley Casey Avery Quinn Morgan Taylor]
      lasts = %w[Nguyen Chen Patel Brooks Hale Ortiz Vega Singh Clarke Wu]

      Array.new(count) do |i|
        persona = PERSONAS.sample(random: rng)
        first = firsts.sample(random: rng)
        last = lasts.sample(random: rng)
        {
          email: "#{first.downcase}.#{last.downcase}.import#{Time.now.to_i}#{i}@example.com",
          first_name: first,
          last_name: last,
          country: %w[AU NZ GB US SG].sample(random: rng),
          persona: persona
        }
      end
    end

    def initialize(rows:, source:)
      @rows = Array(rows)
      @source = source
      @rng = Random.new
    end

    def call
      created = 0
      skipped = 0

      ActiveRecord::Base.transaction do
        @rows.each do |row|
          attrs = normalize(row)
          if attrs[:email].blank? || Contact.exists?(email: attrs[:email])
            skipped += 1
            next
          end

          contact = Contact.create!(
            email: attrs[:email],
            first_name: attrs[:first_name],
            last_name: attrs[:last_name],
            country: attrs[:country],
            source: @source,
            pending_allocation: true
          )
          seed_hubspot_activity!(contact, attrs[:persona])
          created += 1
        end
      end

      Result.new(
        created: created,
        skipped: skipped,
        pending_count: Contact.pending_allocation.count
      )
    end

    private

    def normalize(row)
      h = row.respond_to?(:with_indifferent_access) ? row.with_indifferent_access : row.to_h.with_indifferent_access
      {
        email: h[:email].to_s.strip.downcase,
        first_name: h[:first_name].presence || h[:first].presence || "New",
        last_name: h[:last_name].presence || h[:last].presence || "Contact",
        country: h[:country].presence || "AU",
        persona: (h[:persona].presence || "mixed").to_s.downcase
      }
    end

    def seed_hubspot_activity!(contact, persona)
      activities = []
      email_events = []

      case persona
      when "japan"
        activities = [
          { type: "PAGE_VIEW", url: "/japan-tours", title: "Japan Tours", timestamp: 3.days.ago.iso8601 },
          { type: "PAGE_VIEW", url: "/tokyo-hotels", timestamp: 2.days.ago.iso8601 },
          { type: "PAGE_VIEW", url: "/osaka-packages", timestamp: 1.day.ago.iso8601 },
          { type: "FORM_SUBMISSION", form: "Japan trip enquiry", url: "/japan-tours", timestamp: 1.day.ago.iso8601 }
        ]
        email_events = [
          { type: "CLICK", campaign: "Japan Travel Deals", url: "https://horizon.example/japan-packages", timestamp: 2.days.ago.iso8601 }
        ]
        if @rng.rand < 0.5
          activities << { type: "PURCHASE", destination: "Japan", style: "mid", value: @rng.rand(1800..4200), timestamp: 5.days.ago.iso8601 }
        end
      when "luxury"
        activities = [
          { type: "PAGE_VIEW", url: "/luxury-villas", timestamp: 2.days.ago.iso8601 },
          { type: "PAGE_VIEW", url: "/maldives-overwater", timestamp: 1.day.ago.iso8601 },
          { type: "CTA_CLICK", cta: "Book luxury consultation", url: "/luxury-villas", timestamp: 1.day.ago.iso8601 },
          { type: "PURCHASE", destination: "Maldives", style: "luxury", value: @rng.rand(3000..7500), timestamp: 4.days.ago.iso8601 }
        ]
      when "budget"
        activities = [
          { type: "PAGE_VIEW", url: "/thailand-deals", timestamp: 3.days.ago.iso8601 },
          { type: "PAGE_VIEW", url: "/budget-hostel-pass", timestamp: 2.days.ago.iso8601 },
          { type: "CTA_CLICK", cta: "Flash deals", url: "/flash-deals", timestamp: 1.day.ago.iso8601 }
        ]
        email_events = [
          { type: "CLICK", campaign: "Flash deals", url: "https://horizon.example/flash-deals", timestamp: 1.day.ago.iso8601 }
        ]
        if @rng.rand < 0.6
          activities << { type: "PURCHASE", destination: "Thailand", style: "budget", value: @rng.rand(400..1000), timestamp: 6.days.ago.iso8601 }
        end
      when "engaged"
        email_events = Array.new(8) { |i| { type: "OPEN", campaign: "Weekend tips", timestamp: (i + 1).days.ago.iso8601 } }
        email_events += Array.new(4) { |i| { type: "CLICK", campaign: "New routes", url: "https://horizon.example/offers", timestamp: (i + 1).days.ago.iso8601 } }
      else
        activities = [
          { type: "PAGE_VIEW", url: %w[/spain-cities /canada-guides /mexico-beaches].sample(random: @rng), timestamp: 4.days.ago.iso8601 }
        ]
        email_events = [
          { type: "OPEN", campaign: "Newsletter", timestamp: 3.days.ago.iso8601 }
        ]
      end

      Hubspot::IngestActivities.call(
        contact: contact,
        activities: activities,
        email_events: email_events
      )
    end
  end
end
