module Contacts
  # Imports contacts and attaches enough behavioural events for segmentation.
  # New rows are flagged pending_allocation so incremental analyse can place
  # them without reshuffling existing memberships.
  class Import
    Result = Struct.new(:created, :skipped, :pending_count, keyword_init: true)

    PERSONAS = %w[japan luxury budget engaged mixed].freeze

    def self.call(rows:, source: "import")
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
          seed_events!(contact, attrs[:persona])
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

    def seed_events!(contact, persona)
      case persona
      when "japan"
        3.times do
          add(contact, "destination_viewed", destination: %w[Japan Tokyo Kyoto].sample(random: @rng))
        end
        add(contact, "campaign_clicked", campaign: "Japan spring")
        add(contact, "purchase", destination: "Japan", style: "mid", value: @rng.rand(1800..4200)) if @rng.rand < 0.5
      when "luxury"
        add(contact, "product_viewed", product: "Luxury villa", style: "luxury")
        add(contact, "destination_viewed", destination: %w[Paris Maldives Italy].sample(random: @rng))
        add(contact, "purchase", destination: "Maldives", style: "luxury", value: @rng.rand(3000..7500))
      when "budget"
        add(contact, "destination_viewed", destination: %w[Thailand Bali Vietnam].sample(random: @rng))
        add(contact, "product_viewed", product: "Discount hostel pass", style: "budget")
        add(contact, "campaign_clicked", campaign: "Flash deals")
        add(contact, "purchase", destination: "Thailand", style: "budget", value: @rng.rand(400..1000)) if @rng.rand < 0.6
      when "engaged"
        8.times { add(contact, "campaign_opened", campaign: "Weekend tips") }
        4.times { add(contact, "campaign_clicked", campaign: "New routes") }
      else
        add(contact, "destination_viewed", destination: %w[Spain Canada Mexico].sample(random: @rng))
        add(contact, "campaign_opened", campaign: "Newsletter")
      end
    end

    def add(contact, type, **meta)
      contact.events.create!(
        event_type: type,
        occurred_at: @rng.rand(1..20).days.ago,
        metadata: meta
      )
    end
  end
end
