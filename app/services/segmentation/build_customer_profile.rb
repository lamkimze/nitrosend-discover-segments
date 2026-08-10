module Segmentation
  class BuildCustomerProfile
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
        destinations_viewed: destinations,
        interests: interests,
        engagement: {
          emails_opened: count_of("campaign_opened"),
          emails_clicked: count_of("campaign_clicked")
        },
        purchases: {
          count: purchases.size,
          average_value: average_purchase_value,
          destinations: purchase_destinations,
          styles: purchase_styles
        },
        products_viewed: products
      }
    end

    private

    def count_of(type)
      @events.count { |e| e.event_type == type }
    end

    def destinations
      @events
        .select { |e| e.event_type == "destination_viewed" }
        .map { |e| e.metadata["destination"] }
        .compact
    end

    def products
      @events
        .select { |e| e.event_type == "product_viewed" }
        .map { |e| e.metadata["product"] || e.metadata["style"] }
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

    def interests
      tags = []
      dest_counts = destinations.tally
      top_dest = dest_counts.max_by { |_, c| c }&.first
      tags << top_dest if top_dest && dest_counts[top_dest] >= 2

      if purchase_styles.include?("luxury") || products.grep(/luxury/i).any?
        tags << "Luxury travel"
      end
      if purchase_styles.include?("budget") || products.grep(/budget|discount/i).any?
        tags << "Budget travel"
      end
      if count_of("campaign_opened") + count_of("campaign_clicked") >= 8
        tags << "Highly engaged"
      end

      tags.uniq
    end
  end
end
