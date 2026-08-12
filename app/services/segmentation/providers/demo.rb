module Segmentation
  module Providers
    # Deterministic provider for reliable staging demos.
    # Scores HubSpot-style signals (pages, email, forms, purchases) into audiences.
    # Production can swap to OpenAI via SEGMENTATION_PROVIDER=openai.
    class Demo < Segmentation::Provider
      DEFINITIONS = [
        {
          key: "japan-enthusiasts",
          name: "Japan Enthusiasts",
          description: "Repeated Japan page visits, related email clicks, and trip purchases from CRM activity.",
          min_score: 0.55
        },
        {
          key: "luxury-travellers",
          name: "Luxury Travellers",
          description: "High-value purchases and luxury page / CTA engagement.",
          min_score: 0.55
        },
        {
          key: "budget-travellers",
          name: "Budget Travellers",
          description: "Value destinations, deal CTAs, and lower-average purchases.",
          min_score: 0.55
        },
        {
          key: "highly-engaged",
          name: "Highly Engaged",
          description: "Consistent email opens and clicks — ready for timely sends.",
          min_score: 0.6
        },
        {
          key: "frequent-buyers",
          name: "Frequent Buyers",
          description: "Multiple purchases on record — strong candidates for win-back or upsell.",
          min_score: 0.55
        },
        {
          key: "dormant-customers",
          name: "Dormant Customers",
          description: "Little recent website or email activity — candidates for re-engagement.",
          min_score: 0.55
        }
      ].freeze

      def analyse(profiles)
        segments = DEFINITIONS.filter_map do |definition|
          members = profiles.filter_map { |profile| member_for(definition[:key], profile) }
          next if members.size < 8

          confidence = (members.sum { |m| m[:score] } / members.size).round(4)
          {
            name: definition[:name],
            description: definition[:description],
            confidence: confidence,
            evidence: evidence_for(definition[:key], profiles, members),
            members: members.sort_by { |m| -m[:score] }
          }
        end

        { segments: segments }
      end

      private

      def member_for(key, profile)
        score, reason = score_for(key, profile)
        return if score < DEFINITIONS.find { |d| d[:key] == key }[:min_score]

        { contact_id: profile[:contact_id], score: score.round(4), reason: reason }
      end

      def score_for(key, profile)
        case key
        when "japan-enthusiasts" then japan_score(profile)
        when "luxury-travellers" then luxury_score(profile)
        when "budget-travellers" then budget_score(profile)
        when "highly-engaged" then engaged_score(profile)
        when "frequent-buyers" then frequent_buyer_score(profile)
        when "dormant-customers" then dormant_score(profile)
        else
          [ 0.0, nil ]
        end
      end

      def japan_score(profile)
        pages = Array(profile[:pages_visited])
        japan_pages = pages.count { |u| u.to_s.match?(/japan|tokyo|kyoto|osaka/i) }
        interests = Array(profile[:page_interests]) + Array(profile[:destinations_viewed])
        japan_interest = interests.count { |d| d.to_s.match?(/japan/i) }
        clicks = profile.dig(:engagement, :emails_clicked).to_i
        clicked_japan = Array(profile.dig(:engagement, :campaigns_clicked)).any? { |c| c.to_s.match?(/japan/i) }
        forms = Array(profile[:forms_submitted]).count { |f| f.to_s.match?(/japan/i) }
        purchases = Array(profile.dig(:purchases, :destinations)).count { |d| d.to_s.match?(/japan/i) }

        score = 0.15
        score += [ japan_pages * 0.12, 0.4 ].min
        score += 0.12 if japan_interest.positive?
        score += 0.15 if clicked_japan || (clicks.positive? && japan_pages.positive?)
        score += 0.12 if forms.positive?
        score += 0.2 if purchases.positive?

        reason = if purchases.positive?
          "Purchased Japan travel after viewing Japan pages and related email links"
        elsif japan_pages >= 3
          "Repeatedly visited Japan pages (e.g. tours, hotels) in HubSpot website activity"
        elsif clicked_japan
          "Clicked Japan campaign links and browsed related destination pages"
        else
          "Showed Japan interest across website visits and email engagement"
        end

        [ [ score, 0.99 ].min, reason ]
      end

      def luxury_score(profile)
        avg = profile.dig(:purchases, :average_value).to_f
        styles = Array(profile.dig(:purchases, :styles)) + Array(profile[:products_viewed])
        luxury_hits = styles.count { |s| s.to_s.match?(/luxury|premium|suite|first.?class/i) }
        luxury_pages = Array(profile[:pages_visited]).count { |u| u.to_s.match?(/luxury|villa|maldives|private/i) }

        score = 0.12
        score += 0.35 if avg >= 2500
        score += 0.25 if avg >= 4000
        score += [ luxury_hits * 0.1, 0.3 ].min
        score += [ luxury_pages * 0.1, 0.2 ].min

        reason = if avg >= 2500
          "Average purchase value $#{avg.round(0)} with luxury page / product interest"
        else
          "Visited luxury package pages and premium travel CTAs"
        end

        [ [ score, 0.99 ].min, reason ]
      end

      def budget_score(profile)
        avg = profile.dig(:purchases, :average_value).to_f
        styles = Array(profile.dig(:purchases, :styles)) + Array(profile[:products_viewed])
        budget_hits = styles.count { |s| s.to_s.match?(/budget|discount|deal|hostel/i) }
        value_pages = Array(profile[:pages_visited]).count { |u| u.to_s.match?(/thailand|bali|vietnam|portugal|greece|budget|deal|hostel/i) }
        deal_clicks = Array(profile.dig(:engagement, :campaigns_clicked)).count { |c| c.to_s.match?(/deal|flash|discount/i) }
        deal_clicks += Array(profile[:cta_clicks]).count { |c| c.to_s.match?(/deal|discount|budget/i) }

        score = 0.12
        score += 0.28 if avg.positive? && avg < 1200
        score += 0.12 if avg.zero? && (budget_hits.positive? || value_pages.positive?)
        score += [ budget_hits * 0.1, 0.25 ].min
        score += [ value_pages * 0.08, 0.24 ].min
        score += 0.1 if deal_clicks.positive?

        reason = if deal_clicks.positive? || budget_hits.positive?
          "Engaged with discount CTAs / deal emails and value destination pages"
        else
          "Browsed value destinations with lower purchase affinity"
        end

        [ [ score, 0.99 ].min, reason ]
      end

      def engaged_score(profile)
        opens = profile.dig(:engagement, :emails_opened).to_i
        clicks = profile.dig(:engagement, :emails_clicked).to_i
        total = opens + clicks
        score = 0.1 + [ total * 0.06, 0.7 ].min
        score += 0.15 if clicks >= 4
        score += 0.1 if opens >= 8

        reason = "Opened #{opens} and clicked #{clicks} marketing emails in HubSpot engagement data"
        [ [ score, 0.99 ].min, reason ]
      end

      def frequent_buyer_score(profile)
        count = profile.dig(:purchases, :count).to_i
        avg = profile.dig(:purchases, :average_value).to_f
        score = 0.1
        score += 0.45 if count >= 2
        score += 0.25 if count >= 3
        score += 0.1 if avg >= 1500

        return [ 0.0, nil ] if count < 2

        reason = "Recorded #{count} purchases in CRM deal / purchase history"
        [ [ score, 0.99 ].min, reason ]
      end

      def dormant_score(profile)
        last_at = profile[:last_activity_at]
        return [ 0.0, nil ] if last_at.blank?

        days = ((Time.current - last_at) / 1.day).floor
        opens = profile.dig(:engagement, :emails_opened).to_i
        clicks = profile.dig(:engagement, :emails_clicked).to_i
        pages = Array(profile[:pages_visited]).size

        score = 0.0
        score += 0.45 if days >= 45
        score += 0.25 if days >= 70
        score += 0.15 if opens <= 1 && clicks.zero?
        score += 0.1 if pages <= 1

        return [ 0.0, nil ] if days < 40

        reason = "Last HubSpot activity #{days} days ago — low recent email and website engagement"
        [ [ score, 0.99 ].min, reason ]
      end

      def evidence_for(key, profiles, members)
        ids = members.map { |m| m[:contact_id] }.to_set
        subset = profiles.select { |p| ids.include?(p[:contact_id]) }
        size = subset.size.to_f
        return [] if size.zero?

        case key
        when "japan-enthusiasts"
          viewed = subset.count { |p| Array(p[:pages_visited]).any? { |u| u.to_s.match?(/japan|tokyo|kyoto|osaka/i) } }
          clicked = subset.count { |p| Array(p.dig(:engagement, :campaigns_clicked)).any? { |c| c.to_s.match?(/japan/i) } }
          bought = subset.count { |p| Array(p.dig(:purchases, :destinations)).any? { |d| d.to_s.match?(/japan/i) } }
          [
            "#{pct(viewed, size)} viewed Japan website pages",
            "#{pct(clicked, size)} clicked Japan-related email links",
            "#{pct(bought, size)} purchased Japan travel packages"
          ]
        when "luxury-travellers"
          high = subset.count { |p| p.dig(:purchases, :average_value).to_f >= 2500 }
          lux = subset.count { |p| Array(p[:pages_visited]).any? { |u| u.to_s.match?(/luxury|villa|maldives|private/i) } || (Array(p[:products_viewed]) + Array(p.dig(:purchases, :styles))).any? { |s| s.to_s.match?(/luxury|premium/i) } }
          [
            "#{pct(high, size)} have high average purchase value",
            "#{pct(lux, size)} browsed luxury pages or bought premium packages"
          ]
        when "budget-travellers"
          low = subset.count { |p| v = p.dig(:purchases, :average_value).to_f; v.positive? && v < 1200 }
          deals = subset.count { |p| Array(p[:pages_visited]).any? { |u| u.to_s.match?(/budget|deal|hostel|thailand|bali/i) } || (Array(p[:products_viewed]) + Array(p.dig(:purchases, :styles))).any? { |s| s.to_s.match?(/budget|discount|deal/i) } }
          [
            "#{pct(deals, size)} engaged with deal or value destination content",
            "#{pct(low, size)} show lower average purchase value"
          ]
        when "highly-engaged"
          active = subset.count { |p| p.dig(:engagement, :emails_opened).to_i + p.dig(:engagement, :emails_clicked).to_i >= 8 }
          clickers = subset.count { |p| p.dig(:engagement, :emails_clicked).to_i >= 3 }
          [
            "#{pct(active, size)} consistently open and click marketing emails",
            "#{pct(clickers, size)} clicked 3+ campaign emails"
          ]
        when "frequent-buyers"
          multi = subset.count { |p| p.dig(:purchases, :count).to_i >= 2 }
          [
            "#{pct(multi, size)} have 2+ purchases on record",
            "Inferred from CRM purchase / deal history — not in-app product analytics"
          ]
        when "dormant-customers"
          stale = subset.count { |p| p[:last_activity_at].present? && p[:last_activity_at] < 45.days.ago }
          [
            "#{pct(stale, size)} have no meaningful activity in 45+ days",
            "Built from HubSpot website + email recency, not product feature usage"
          ]
        else
          []
        end
      end

      def pct(count, total)
        "#{((count / total) * 100).round}%"
      end
    end
  end
end
