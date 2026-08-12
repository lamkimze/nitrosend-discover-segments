module Segmentation
  # Rolls HubSpot-style CRM + website + email activity into a compact profile
  # the segmentation provider can score.
  #
  #   HubSpot
  #   ├── Contact data
  #   ├── Website page views
  #   ├── Email opens / clicks
  #   ├── Forms / CTAs
  #   └── Purchase / deal history
  #           ↓
  #   BuildCustomerProfile
  #           ↓
  #   AI segments (Japan, Luxury, …)
  class BuildCustomerProfile
    URL_INTEREST_RULES = [
      [ /japan|tokyo|kyoto|osaka/i, "Japan" ],
      [ /luxury|villa|maldives|suite|private.?escape|first.?class/i, "Luxury" ],
      [ /budget|hostel|discount|deal|flash/i, "Budget" ],
      [ /thailand|bali|vietnam|portugal|greece/i, "Value destinations" ]
    ].freeze

    def self.call(contact)
      new(contact).call
    end

    def initialize(contact)
      @contact = contact
      @events = contact.events.to_a
    end

    def call
      {
        contact_id: @contact.id,
        source: @contact.source,
        pages_visited: pages_visited,
        page_interests: page_interests,
        # Kept for scoring clarity — interests inferred from website URLs.
        destinations_viewed: page_interests,
        products_viewed: product_signals,
        engagement: {
          emails_opened: count_of("email_open"),
          emails_clicked: count_of("email_click"),
          campaigns_opened: campaign_names("email_open"),
          campaigns_clicked: campaign_names("email_click")
        },
        forms_submitted: forms_submitted,
        cta_clicks: cta_clicks,
        purchases: {
          count: purchases.size,
          average_value: average_purchase_value,
          destinations: purchase_destinations,
          styles: purchase_styles
        },
        last_activity_at: last_activity_at,
        interests: interests
      }
    end

    private

    def count_of(type)
      @events.count { |e| e.event_type == type }
    end

    def pages_visited
      @events
        .select { |e| e.event_type == "page_view" }
        .map { |e| e.metadata["url"] }
        .compact
    end

    def page_interests
      pages_visited.filter_map { |url| interest_for(url) }.uniq
    end

    def interest_for(text)
      URL_INTEREST_RULES.each do |pattern, label|
        return label if text.to_s.match?(pattern)
      end
      nil
    end

    def product_signals
      signals = []
      pages_visited.each do |url|
        signals << "Luxury" if url.to_s.match?(/luxury|villa|suite|private/i)
        signals << "Budget" if url.to_s.match?(/budget|hostel|discount|deal/i)
      end
      cta_clicks.each do |cta|
        signals << "Luxury" if cta.to_s.match?(/luxury|villa|premium/i)
        signals << "Budget" if cta.to_s.match?(/budget|discount|deal/i)
      end
      signals
    end

    def campaign_names(type)
      @events
        .select { |e| e.event_type == type }
        .map { |e| e.metadata["campaign"] }
        .compact
        .uniq
    end

    def forms_submitted
      @events
        .select { |e| e.event_type == "form_submission" }
        .map { |e| e.metadata["form"] }
        .compact
    end

    def cta_clicks
      @events
        .select { |e| e.event_type == "cta_click" }
        .map { |e| e.metadata["cta"] || e.metadata["url"] }
        .compact
    end

    def purchases
      @events.select { |e| e.event_type == "purchase" }
    end

    def average_purchase_value
      return 0 if purchases.empty?

      values = purchases.map { |e| e.metadata["value"].to_f }
      (values.sum / values.size).round(2)
    end

    def purchase_destinations
      purchases.map { |e| e.metadata["destination"] }.compact
    end

    def purchase_styles
      purchases.map { |e| e.metadata["style"] }.compact
    end

    def last_activity_at
      @events.map(&:occurred_at).max
    end

    def interests
      tags = page_interests.dup

      if purchase_styles.include?("luxury") || product_signals.grep(/luxury/i).any?
        tags << "Luxury travel"
      end
      if purchase_styles.include?("budget") || product_signals.grep(/budget/i).any?
        tags << "Budget travel"
      end
      if count_of("email_open") + count_of("email_click") >= 8
        tags << "Highly engaged"
      end
      if purchases.size >= 2
        tags << "Frequent buyer"
      end

      tags.uniq
    end
  end
end
