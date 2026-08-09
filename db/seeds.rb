# frozen_string_literal: true

# Horizon Travel — deterministic demo audience for Discover Segments.
FIRST_NAMES = %w[
  Avery Blair Cameron Drew Ellis Finley Harper Indigo Jordan Kai
  Logan Morgan Noa Quinn Remy Sage Taylor Avery Brooke Casey
  Dana Eden Flynn Grey Hayden Jules Lane Marlowe Nico Parker
  Reese Skyler Wren Alex Bailey Charlie Dakota Emerson Frankie
].freeze

LAST_NAMES = %w[
  Ashford Blake Chen Duarte Ellis Farrah Grant Hale Ito Jain
  Kessler Lang Moreau Nguyen Okada Patel Quinn Reyes Sato Tran
  Ulrich Vega Walsh Xu Young Zimmerman
].freeze

DESTINATIONS = [ "Japan", "Italy", "New Zealand", "Greece", "Portugal", "Vietnam" ].freeze
STYLES = %w[luxury budget family adventure].freeze

CLUSTER_PLAN = [
  # destination, style, count, spend bias, engagement range
  [ "Japan", "luxury", 18, "high", 70..95 ],
  [ "Japan", "budget", 12, "low", 45..75 ],
  [ "Italy", "luxury", 14, "high", 60..90 ],
  [ "Italy", "family", 11, "mid", 40..70 ],
  [ "New Zealand", "adventure", 13, "mid", 55..85 ],
  [ "Greece", "budget", 10, "low", 35..65 ],
  [ "Portugal", "luxury", 9, "high", 50..80 ],
  [ "Vietnam", "adventure", 8, "mid", 45..75 ]
].freeze

def build_email(name, index)
  local = name.downcase.gsub(/[^a-z]/, ".")
  "#{local}#{index}@example.com"
end

def browse_for(primary, rng)
  others = DESTINATIONS - [ primary ]
  list = [ primary ] * rng.rand(3..6)
  rng.rand(0..2).times { list << others.sample(random: rng) }
  list.shuffle(random: rng)
end

puts "Seeding Horizon Travel contacts…"

rng = Random.new(42)
Contact.delete_all
SegmentMembership.delete_all
Segment.delete_all
Insight.delete_all
DiscoveryRun.delete_all

index = 0

CLUSTER_PLAN.each do |destination, style, count, spend, engagement_range|
  count.times do
    index += 1
    first = FIRST_NAMES.sample(random: rng)
    last = LAST_NAMES.sample(random: rng)
    name = "#{first} #{last}"
    engagement = rng.rand(engagement_range)
    opens = (engagement / 12.0).round + rng.rand(0..3)
    clicks = [ opens - rng.rand(0..4), 0 ].max

    Contact.create!(
      name: name,
      email: build_email(name, index),
      primary_destination: destination,
      trip_style: style,
      spend_band: spend,
      engagement_score: engagement,
      opens_30d: opens,
      clicks_30d: clicks,
      last_opened_at: rng.rand(1..28).days.ago,
      booked_trips: rng.rand(0..3),
      tags: [ style, destination.downcase.tr(" ", "-"), ("vip" if spend == "high" && engagement > 80) ].compact,
      browse_destinations: browse_for(destination, rng),
      notes: nil
    )
  end
end

# Noise / needs-review contacts
12.times do
  index += 1
  first = FIRST_NAMES.sample(random: rng)
  last = LAST_NAMES.sample(random: rng)
  name = "#{first} #{last}"
  weak_destination = [ nil, DESTINATIONS.sample(random: rng) ].sample(random: rng)
  weak_style = [ nil, STYLES.sample(random: rng) ].sample(random: rng)

  Contact.create!(
    name: name,
    email: build_email(name, index),
    primary_destination: weak_destination,
    trip_style: weak_style,
    spend_band: %w[low mid high].sample(random: rng),
    engagement_score: rng.rand(5..35),
    opens_30d: rng.rand(0..2),
    clicks_30d: rng.rand(0..1),
    last_opened_at: rng.rand(40..120).days.ago,
    booked_trips: rng.rand(0..1),
    tags: [ "imported" ],
    browse_destinations: DESTINATIONS.sample(rng.rand(2..4), random: rng),
    notes: "Weak preference signal"
  )
end

# A few cross-signal contacts that browse widely
5.times do
  index += 1
  first = FIRST_NAMES.sample(random: rng)
  last = LAST_NAMES.sample(random: rng)
  name = "#{first} #{last}"

  Contact.create!(
    name: name,
    email: build_email(name, index),
    primary_destination: DESTINATIONS.sample(random: rng),
    trip_style: STYLES.sample(random: rng),
    spend_band: "mid",
    engagement_score: rng.rand(20..45),
    opens_30d: rng.rand(1..3),
    clicks_30d: rng.rand(0..2),
    last_opened_at: rng.rand(5..40).days.ago,
    booked_trips: 0,
    tags: [ "window-shopper" ],
    browse_destinations: DESTINATIONS.shuffle(random: rng),
    notes: "Broad browse history"
  )
end

puts "Created #{Contact.count} contacts."
puts "Run Discover Segments from the app to generate proposals."
