module Segmentation
  module Providers
    # Deterministic provider for reliable staging demos.
    # Production can swap to OpenAI via SEGMENTATION_PROVIDER=openai.
    class Demo < Segmentation::Provider
      DEFINITIONS = [
        {
          key: "japan-travellers",
          name: "Japan Travellers",
          description: "Strong interest in Japan travel across browsing, campaign engagement, and bookings.",
          min_score: 0.55
        },
        {
          key: "luxury-travellers",
          name: "Luxury Travellers",
          description: "High-value purchase behaviour and luxury product browsing.",
          min_score: 0.55
        },
        {
          key: "budget-travellers",
          name: "Budget Travellers",
          description: "Value-led browsing, discount campaign clicks, and lower-average purchases.",
          min_score: 0.55
        },
        {
          key: "highly-engaged",
          name: "Highly Engaged",
          description: "Opens and clicks travel emails consistently — ready for timely sends.",
          min_score: 0.6
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
        when "japan-travellers"
          japan_score(profile)
        when "luxury-travellers"
          luxury_score(profile)
        when "budget-travellers"
          budget_score(profile)
        when "highly-engaged"
          engaged_score(profile)
        else
          [ 0.0, nil ]
        end
      end

      def japan_score(profile)
        dests = Array(profile[:destinations_viewed]) + Array(profile.dig(:purchases, :destinations))
        japanish = dests.count { |d| d.to_s.match?(/japan|tokyo|kyoto|osaka/i) }
        opens = profile.dig(:engagement, :emails_opened).to_i
        clicks = profile.dig(:engagement, :emails_clicked).to_i
        purchases = Array(profile.dig(:purchases, :destinations)).count { |d| d.to_s.match?(/japan/i) }

        score = 0.2
        score += [ japanish * 0.12, 0.45 ].min
        score += 0.15 if clicks.positive? && japanish.positive?
        score += 0.2 if purchases.positive?
        score += 0.05 if opens >= 3

        reason = if purchases.positive?
          "Purchased Japan travel and viewed related destinations"
        elsif japanish >= 3
          "Repeatedly viewed Japan destinations and engaged with related campaigns"
        else
          "Showed Japan interest across browsing and email engagement"
        end

        [ [ score, 0.99 ].min, reason ]
      end

      def luxury_score(profile)
        avg = profile.dig(:purchases, :average_value).to_f
        styles = Array(profile.dig(:purchases, :styles)) + Array(profile[:products_viewed])
        luxury_hits = styles.count { |s| s.to_s.match?(/luxury|premium|suite|first.?class/i) }
        score = 0.15
        score += 0.35 if avg >= 2500
        score += 0.25 if avg >= 4000
        score += [ luxury_hits * 0.12, 0.36 ].min

        reason = if avg >= 2500
          "Average purchase value $#{avg.round(0)} with luxury product interest"
        else
          "Browsed luxury packages and premium travel products"
        end

        [ [ score, 0.99 ].min, reason ]
      end

      def budget_score(profile)
        avg = profile.dig(:purchases, :average_value).to_f
        styles = Array(profile.dig(:purchases, :styles)) + Array(profile[:products_viewed])
        budget_hits = styles.count { |s| s.to_s.match?(/budget|discount|deal|hostel/i) }
        dests = Array(profile[:destinations_viewed])
        value_dests = dests.count { |d| d.to_s.match?(/thailand|bali|vietnam|portugal|greece/i) }

        score = 0.15
        score += 0.3 if avg.positive? && avg < 1200
        score += 0.15 if avg.zero? && budget_hits.positive?
        score += [ budget_hits * 0.12, 0.3 ].min
        score += [ value_dests * 0.08, 0.24 ].min

        reason = if budget_hits.positive?
          "Engaged with discount and value-led travel content"
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

        reason = "Opened #{opens} and clicked #{clicks} campaign emails recently"
        [ [ score, 0.99 ].min, reason ]
      end

      def evidence_for(key, profiles, members)
        ids = members.map { |m| m[:contact_id] }.to_set
        subset = profiles.select { |p| ids.include?(p[:contact_id]) }
        size = subset.size.to_f
        return [] if size.zero?

        case key
        when "japan-travellers"
          viewed = subset.count { |p| Array(p[:destinations_viewed]).any? { |d| d.to_s.match?(/japan|tokyo|kyoto/i) } }
          clicked = subset.count { |p| p.dig(:engagement, :emails_clicked).to_i.positive? && Array(p[:destinations_viewed]).any? { |d| d.to_s.match?(/japan/i) } }
          bought = subset.count { |p| Array(p.dig(:purchases, :destinations)).any? { |d| d.to_s.match?(/japan/i) } }
          [
            "#{pct(viewed, size)} viewed Japan destinations",
            "#{pct(clicked, size)} clicked Japan-related campaigns",
            "#{pct(bought, size)} purchased Japan travel packages"
          ]
        when "luxury-travellers"
          high = subset.count { |p| p.dig(:purchases, :average_value).to_f >= 2500 }
          lux = subset.count { |p| (Array(p[:products_viewed]) + Array(p.dig(:purchases, :styles))).any? { |s| s.to_s.match?(/luxury|premium/i) } }
          [
            "#{pct(high, size)} have high average purchase value",
            "#{pct(lux, size)} browsed or bought luxury packages"
          ]
        when "budget-travellers"
          low = subset.count { |p| v = p.dig(:purchases, :average_value).to_f; v.positive? && v < 1200 }
          deals = subset.count { |p| (Array(p[:products_viewed]) + Array(p.dig(:purchases, :styles))).any? { |s| s.to_s.match?(/budget|discount|deal/i) } }
          [
            "#{pct(deals, size)} engaged with discount or budget content",
            "#{pct(low, size)} show lower average purchase value"
          ]
        when "highly-engaged"
          active = subset.count { |p| p.dig(:engagement, :emails_opened).to_i + p.dig(:engagement, :emails_clicked).to_i >= 8 }
          clickers = subset.count { |p| p.dig(:engagement, :emails_clicked).to_i >= 3 }
          [
            "#{pct(active, size)} are consistently opening and clicking",
            "#{pct(clickers, size)} clicked 3+ campaign emails"
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
