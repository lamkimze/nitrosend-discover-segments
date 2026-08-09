# frozen_string_literal: true

# Deterministic segment discovery for the Horizon Travel demo.
# Groups contacts by destination + trip style, merges thin buckets,
# and attaches human-readable reasons plus campaign recommendations.
class SegmentDiscoveryService
  MIN_SEGMENT_SIZE = 6
  FIXED_SEED = 42

  CAMPAIGN_TEMPLATES = {
    "Japan|luxury" => {
      subject: "Private ryokans & spring cherry viewing — for travellers who notice the details",
      angle: "Lead with exclusive access: a Kyoto ryokan hold, a private tea ceremony, and a slow itinerary that never feels rushed.",
      why: "This group opens luxury Japan content at a high rate and sits in the top spend band. They respond to craft and scarcity, not discounts."
    },
    "Japan|budget" => {
      subject: "Japan without the markup: rail passes, guesthouses, and local eats",
      angle: "Practical value framed as smart travel — JR Pass timing, neighbourhood stays, and free cultural experiences.",
      why: "Budget Japan browsers click itinerary guides more than hotel features. Price clarity and packing tips outperform polish."
    },
    "Italy|luxury" => {
      subject: "A quieter Amalfi — villas, drivers, and tables worth dressing for",
      angle: "Sell ease and taste: private transfers, a villa with a view, and one unforgettable dinner reservation.",
      why: "Luxury Italy contacts show high spend and frequent opens on food-forward campaigns."
    },
    "Italy|family" => {
      subject: "Italy with kids: gelato stops, shorter days, better pacing",
      angle: "Reassure parents with realistic pacing, family suites, and activities that work for mixed ages.",
      why: "Family-tagged Italy contacts browse multi-room stays and open ‘with kids’ guides more than couples’ romance content."
    },
    "New Zealand|adventure" => {
      subject: "South Island trails that earn the sore legs",
      angle: "Lead with route maps, hut bookings, and a gear checklist — then offer a guided option for the hard days.",
      why: "Adventure NZ contacts click trail and activity content heavily; soft scenery emails underperform."
    },
    "Greece|budget" => {
      subject: "Island hopping on a real budget — ferry maths included",
      angle: "Clear cost breakdowns, ferry timing, and hostels/guesthouses that still feel like Greece.",
      why: "Budget Greece browsers engage with logistics emails and skip villa tours."
    },
    "Portugal|luxury" => {
      subject: "Lisbon & Douro at an unhurried pace",
      angle: "Boutique stays, a private Douro tasting, and a schedule with room to wander.",
      why: "Luxury Portugal contacts open wine and design-led content more than beach packages."
    },
    "Vietnam|adventure" => {
      subject: "North Vietnam on two wheels (and two good pairs of shoes)",
      angle: "Motorbike loops, homestays, and guided treks — active, local, and light on resorts.",
      why: "Adventure Vietnam contacts click activity and route content; beach resort sends see weaker opens."
    },
    "_fallback" => {
      subject: "A trip shaped around how you actually travel",
      angle: "Open with a short preference quiz and three itinerary sketches matched to their style.",
      why: "This group shares a clear travel style even when destinations vary. Style-first framing beats a single destination push."
    },
    "_review" => {
      subject: "Still figuring out your next trip? Start here.",
      angle: "A soft re-engagement: three destination teasers and a one-click preference update.",
      why: "These contacts lack a strong destination or style signal. Treat them as discovery, not conversion."
    }
  }.freeze

  Result = Struct.new(:discovery_run, keyword_init: true)

  def self.call(contacts: Contact.all)
    new(contacts).call
  end

  def initialize(contacts)
    @contacts = contacts.to_a
    @rng = Random.new(FIXED_SEED)
  end

  def call
    ActiveRecord::Base.transaction do
      clear_previous_proposed!
      run = DiscoveryRun.create!(
        status: "complete",
        contact_count: @contacts.size,
        segment_count: 0
      )

      buckets = build_buckets
      merged = merge_small_buckets(buckets)
      segments = persist_segments(run, merged)
      persist_insights(run, segments)

      run.update!(segment_count: segments.size)
      Result.new(discovery_run: run)
    end
  end

  private

  def clear_previous_proposed!
    Segment.proposed.find_each(&:destroy)
    # Keep accepted segments and their memberships intact.
  end

  def build_buckets
    buckets = Hash.new { |h, k| h[k] = [] }

    @contacts.each do |contact|
      key = bucket_key_for(contact)
      buckets[key] << contact
    end

    buckets
  end

  def bucket_key_for(contact)
    destination = contact.primary_destination.presence
    style = contact.trip_style.presence

    if destination.blank? || style.blank? || contact.engagement_score < 15
      return [ "_review", "mixed" ]
    end

    # Prefer primary destination; if browse history contradicts strongly, keep primary
    # but low-engagement oddballs go to review.
    if noisy?(contact)
      return [ "_review", "mixed" ]
    end

    [ destination, style ]
  end

  def noisy?(contact)
    browsed = Array(contact.browse_destinations)
    return false if browsed.empty? || contact.primary_destination.blank?

    primary_share = browsed.count { |d| d == contact.primary_destination }.to_f / browsed.size
    primary_share < 0.25 && contact.engagement_score < 40
  end

  def merge_small_buckets(buckets)
    keep = {}
    spill = []

    buckets.each do |key, members|
      if key[0] == "_review"
        spill.concat(members)
      elsif members.size >= MIN_SEGMENT_SIZE
        keep[key] = members
      else
        # Try merging into same-style fallback before review
        style_key = [ "_style", key[1] ]
        keep[style_key] ||= []
        keep[style_key].concat(members)
      end
    end

    # Re-check style merges; tiny ones go to review
    final = {}
    keep.each do |key, members|
      if members.size >= MIN_SEGMENT_SIZE
        final[key] = members.uniq
      else
        spill.concat(members)
      end
    end

    final[[ "_review", "mixed" ]] = spill.uniq if spill.any?
    final
  end

  def persist_segments(run, buckets)
    ordered = buckets.sort_by { |key, members| [ -strength_rank(members), -members.size, key[0].to_s ] }

    ordered.each_with_index.map do |(key, members), index|
      destination, style = key
      pattern = campaign_pattern(destination, style)
      campaign = CAMPAIGN_TEMPLATES[pattern] || CAMPAIGN_TEMPLATES["_fallback"]
      strength = strength_for(members)
      name = name_for(destination, style, members)

      segment = run.segments.create!(
        name: name,
        status: "proposed",
        strength: strength,
        contact_count: members.size,
        destination: destination.start_with?("_") ? nil : destination,
        trip_style: style == "mixed" ? nil : style,
        reasons: reasons_for(destination, style, members),
        campaign_subject: campaign[:subject],
        campaign_angle: campaign[:angle],
        campaign_why: campaign[:why],
        pattern_key: pattern,
        position: index
      )

      members.each do |contact|
        segment.segment_memberships.create!(contact: contact)
      end

      segment
    end
  end

  def campaign_pattern(destination, style)
    return "_review" if destination == "_review"
    return "_fallback" if destination == "_style"

    key = "#{destination}|#{style}"
    CAMPAIGN_TEMPLATES.key?(key) ? key : "_fallback"
  end

  def name_for(destination, style, members)
    if destination == "_review"
      return "Needs a closer look"
    end

    if destination == "_style"
      return "#{style.capitalize} travellers · mixed destinations"
    end

    style_label = {
      "luxury" => "Luxury seekers",
      "budget" => "Budget explorers",
      "family" => "Family travellers",
      "adventure" => "Adventure travellers"
    }[style] || style.to_s.capitalize

    "#{destination} · #{style_label}"
  end

  def strength_for(members)
    avg = members.sum(&:engagement_score).to_f / members.size
    cohesion = destination_cohesion(members)

    if avg >= 65 && cohesion >= 0.7 && members.size >= 10
      "strong"
    elsif avg >= 40 && cohesion >= 0.45
      "moderate"
    else
      "emerging"
    end
  end

  def strength_rank(members)
    { "strong" => 3, "moderate" => 2, "emerging" => 1 }[strength_for(members)]
  end

  def destination_cohesion(members)
    destinations = members.map(&:primary_destination).compact
    return 0.0 if destinations.empty?

    top = destinations.tally.max_by { |_, c| c }[1]
    top.to_f / members.size
  end

  def reasons_for(destination, style, members)
    reasons = []
    size = members.size

    if destination == "_review"
      reasons << "#{size} contacts lack a clear destination or style signal"
      quiet = members.count { |c| c.engagement_score < 25 }
      reasons << "#{percent(quiet, size)} have been quiet in the last 30 days" if quiet.positive?
      reasons << "Worth a preference-update campaign before hard-selling a destination"
      return reasons
    end

    if destination == "_style"
      reasons << "#{percent(size, size)} share a #{style} travel style across different destinations"
      high = members.count { |c| c.engagement_score >= 50 }
      reasons << "#{percent(high, size)} are actively opening trip emails"
      reasons << "Style-first messaging will travel better than a single destination push"
      return reasons
    end

    dest_match = members.count { |c| c.primary_destination == destination }
    reasons << "#{percent(dest_match, size)} show a primary interest in #{destination}"

    style_match = members.count { |c| c.trip_style == style }
    reasons << "#{percent(style_match, size)} lean #{style} in trip style and browsing"

    if style == "luxury"
      high_spend = members.count { |c| c.spend_band == "high" }
      reasons << "#{percent(high_spend, size)} sit in the top spend band" if high_spend.positive?
    elsif style == "budget"
      low_spend = members.count { |c| c.spend_band == "low" }
      reasons << "#{percent(low_spend, size)} consistently browse value-led itineraries" if low_spend.positive?
    end

    engaged = members.count { |c| c.opens_30d >= 3 }
    if engaged.positive?
      reasons << "#{percent(engaged, size)} opened 3+ trip emails in the last 30 days"
    else
      clicked = members.count { |c| c.clicks_30d >= 1 }
      reasons << "#{percent(clicked, size)} clicked a destination guide recently" if clicked.positive?
    end

    booked = members.count { |c| c.booked_trips.positive? }
    reasons << "#{percent(booked, size)} have booked with Horizon before" if booked >= (size * 0.3)

    reasons.first(3)
  end

  def percent(count, total)
    return "0%" if total.zero?

    "#{((count.to_f / total) * 100).round}%"
  end

  def persist_insights(run, segments)
    insights = []
    contacts = @contacts

    # Popular destinations
    dest_counts = contacts.map(&:primary_destination).compact.tally.sort_by { |_, c| -c }
    if dest_counts.any?
      top_name, top_count = dest_counts.first
      share = percent(top_count, contacts.size)
      insights << [ "trend", "#{top_name} is the clearest destination signal right now — #{share} of contacts lead with it." ]
    end

    # Style split
    styles = contacts.map(&:trip_style).compact.tally
    if styles["luxury"] && styles["budget"]
      lux = percent(styles["luxury"], contacts.size)
      bud = percent(styles["budget"], contacts.size)
      insights << [ "split", "Luxury (#{lux}) and budget (#{bud}) interests are both material — one calendar of sends will under-serve one of them." ]
    end

    # Engagement change proxy: quiet vs active
    quiet = contacts.count { |c| c.engagement_score < 25 }
    if quiet.positive?
      insights << [ "risk", "#{percent(quiet, contacts.size)} of the list looks quiet. A preference refresh may recover more than another blast." ]
    end

    # Strong segment callout
    strong = segments.select { |s| s.strength == "strong" }
    if strong.any?
      names = strong.map(&:name).first(2).join(" and ")
      insights << [ "opportunity", "#{names} #{strong.size == 1 ? "looks" : "look"} ready for a dedicated send — strong cohesion and engagement." ]
    end

    # Rising browse interest (simulate from browse tags)
    japan_browsers = contacts.count { |c| Array(c.browse_destinations).include?("Japan") }
    japan_primary = contacts.count { |c| c.primary_destination == "Japan" }
    if japan_browsers > japan_primary
      insights << [ "trend", "Japan browse interest outpaces declared preference — demand may be building ahead of your next Japan send." ]
    end

    insights.first(5).each_with_index do |(kind, body), index|
      run.insights.create!(kind: kind, body: body, position: index)
    end
  end
end
