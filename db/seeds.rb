# frozen_string_literal: true

# Horizon Travel — ~500 contacts with behaviour that implies smart audiences.
# Segments are NOT stored here; AnalyseAudience discovers them from events.

FIRST = %w[
  Avery Blair Cameron Drew Ellis Finley Harper Indigo Jordan Kai Logan Morgan
  Noa Quinn Remy Sage Taylor Brooke Casey Dana Eden Flynn Grey Hayden Jules
  Lane Marlowe Nico Parker Reese Skyler Wren Alex Bailey Charlie Dakota Emerson
].freeze

LAST = %w[
  Ashford Blake Chen Duarte Ellis Farrah Grant Hale Ito Jain Kessler Lang
  Moreau Nguyen Okada Patel Quinn Reyes Sato Tran Ulrich Vega Walsh Xu Young
].freeze

COUNTRIES = %w[AU NZ GB US SG JP].freeze

def email_for(first, last, i)
  "#{first.downcase}.#{last.downcase}#{i}@example.com"
end

def add_event(contact, type, at:, **meta)
  contact.events.create!(
    event_type: type,
    occurred_at: at,
    metadata: meta
  )
end

puts "Seeding Smart Audiences demo data…"

rng = Random.new(42)

SegmentMembership.delete_all
Campaign.delete_all
Segment.delete_all
Event.delete_all
Contact.delete_all
AiAnalysisRun.delete_all

contacts = []

500.times do |i|
  first = FIRST.sample(random: rng)
  last = LAST.sample(random: rng)
  contacts << Contact.create!(
    email: email_for(first, last, i + 1),
    first_name: first,
    last_name: last,
    country: COUNTRIES.sample(random: rng),
    source: %w[import csv mailchimp signup].sample(random: rng)
  )
end

# Persona buckets by index ranges — behaviour only, no segment rows yet.
japan = contacts[0...110]
luxury = contacts[90...200]   # overlap with japan intentionally
budget = contacts[180...320]
engaged = contacts[280...420]
noise = contacts[400...500]

japan.each do |c|
  3.times { add_event(c, "destination_viewed", at: rng.rand(2..40).days.ago, destination: %w[Japan Tokyo Kyoto Osaka].sample(random: rng)) }
  add_event(c, "campaign_opened", at: rng.rand(1..20).days.ago, campaign: "Japan spring") if rng.rand < 0.8
  add_event(c, "campaign_clicked", at: rng.rand(1..18).days.ago, campaign: "Japan spring") if rng.rand < 0.55
  if rng.rand < 0.35
    add_event(c, "purchase", at: rng.rand(5..60).days.ago, destination: "Japan", style: %w[luxury mid].sample(random: rng), value: rng.rand(1800..5200))
  end
end

luxury.each do |c|
  add_event(c, "product_viewed", at: rng.rand(1..30).days.ago, product: "Luxury villa", style: "luxury")
  add_event(c, "destination_viewed", at: rng.rand(1..25).days.ago, destination: %w[Paris Switzerland Maldives Italy].sample(random: rng))
  if rng.rand < 0.7
    add_event(c, "purchase", at: rng.rand(3..50).days.ago, destination: %w[France Italy Maldives].sample(random: rng), style: "luxury", value: rng.rand(2800..7800))
  end
  add_event(c, "campaign_opened", at: rng.rand(1..15).days.ago, campaign: "Private escapes") if rng.rand < 0.5
end

budget.each do |c|
  add_event(c, "destination_viewed", at: rng.rand(1..35).days.ago, destination: %w[Thailand Bali Vietnam Portugal Greece].sample(random: rng))
  add_event(c, "product_viewed", at: rng.rand(1..28).days.ago, product: "Discount hostel pass", style: "budget")
  add_event(c, "campaign_clicked", at: rng.rand(1..22).days.ago, campaign: "Flash deals") if rng.rand < 0.65
  if rng.rand < 0.55
    add_event(c, "purchase", at: rng.rand(4..55).days.ago, destination: %w[Thailand Bali Vietnam].sample(random: rng), style: "budget", value: rng.rand(350..1100))
  end
end

engaged.each do |c|
  rng.rand(6..14).times do
    add_event(c, "campaign_opened", at: rng.rand(1..45).days.ago, campaign: %w[Weekend tips New routes Member offers].sample(random: rng))
  end
  rng.rand(3..8).times do
    add_event(c, "campaign_clicked", at: rng.rand(1..40).days.ago, campaign: %w[Weekend tips New routes].sample(random: rng))
  end
  add_event(c, "destination_viewed", at: rng.rand(1..20).days.ago, destination: %w[Japan Italy NZ Greece].sample(random: rng)) if rng.rand < 0.5
end

noise.each do |c|
  add_event(c, "destination_viewed", at: rng.rand(10..90).days.ago, destination: %w[Canada Mexico Spain].sample(random: rng)) if rng.rand < 0.6
  add_event(c, "campaign_opened", at: rng.rand(20..100).days.ago, campaign: "Newsletter") if rng.rand < 0.4
end

puts "Contacts: #{Contact.count}"
puts "Events:   #{Event.count}"
puts "Run Analyse audience from the app to discover Smart Audiences."
