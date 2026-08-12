# frozen_string_literal: true

# Horizon Travel — ~500 contacts with HubSpot-style CRM / website / email activity.
# Segments are NOT stored here; AnalyseAudience discovers them from events.
#
# Simulated sync shape:
#   HubSpot (contacts + page views + email engagement + purchases)
#       ↓
#   AI engine
#       ↓
#   Smart Audiences

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

puts "Seeding HubSpot-style activity for Smart Audiences…"

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
    source: %w[hubspot hubspot hubspot import csv].sample(random: rng)
  )
end

# Persona buckets by index — behaviour only, no segment rows yet.
japan = contacts[0...110]
luxury = contacts[90...200]
budget = contacts[180...320]
engaged = contacts[280...420]
buyers = contacts[50...90] + contacts[200...230]
noise = contacts[400...500]

japan.each do |c|
  %w[/japan-tours /tokyo-hotels /osaka-packages /kyoto-guides].sample(3, random: rng).each do |url|
    add_event(c, "page_view", at: rng.rand(2..40).days.ago, url: url, title: url.delete_prefix("/").tr("-", " ").titleize)
  end
  add_event(c, "email_open", at: rng.rand(1..20).days.ago, campaign: "Japan Travel Deals") if rng.rand < 0.8
  if rng.rand < 0.55
    add_event(c, "email_click", at: rng.rand(1..18).days.ago, campaign: "Japan Travel Deals", url: "https://horizon.example/japan-packages")
  end
  add_event(c, "form_submission", at: rng.rand(1..25).days.ago, form: "Japan trip enquiry", url: "/japan-tours") if rng.rand < 0.35
  if rng.rand < 0.35
    add_event(c, "purchase", at: rng.rand(5..60).days.ago, destination: "Japan", style: %w[luxury mid].sample(random: rng), value: rng.rand(1800..5200))
  end
end

luxury.each do |c|
  add_event(c, "page_view", at: rng.rand(1..30).days.ago, url: "/luxury-villas", title: "Luxury Villas")
  add_event(c, "page_view", at: rng.rand(1..25).days.ago, url: %w[/maldives-overwater /private-escapes-paris /switzerland-suites].sample(random: rng))
  add_event(c, "cta_click", at: rng.rand(1..20).days.ago, cta: "Book luxury consultation", url: "/luxury-villas") if rng.rand < 0.5
  if rng.rand < 0.7
    add_event(c, "purchase", at: rng.rand(3..50).days.ago, destination: %w[France Italy Maldives].sample(random: rng), style: "luxury", value: rng.rand(2800..7800))
  end
  add_event(c, "email_open", at: rng.rand(1..15).days.ago, campaign: "Private escapes") if rng.rand < 0.5
end

budget.each do |c|
  add_event(c, "page_view", at: rng.rand(1..35).days.ago, url: %w[/thailand-deals /bali-hostels /vietnam-budget-trips /portugal-value /greece-deals].sample(random: rng))
  add_event(c, "page_view", at: rng.rand(1..28).days.ago, url: "/budget-hostel-pass", title: "Discount hostel pass")
  add_event(c, "cta_click", at: rng.rand(1..22).days.ago, cta: "Flash deals", url: "/flash-deals") if rng.rand < 0.65
  add_event(c, "email_click", at: rng.rand(1..22).days.ago, campaign: "Flash deals", url: "https://horizon.example/flash-deals") if rng.rand < 0.5
  if rng.rand < 0.55
    add_event(c, "purchase", at: rng.rand(4..55).days.ago, destination: %w[Thailand Bali Vietnam].sample(random: rng), style: "budget", value: rng.rand(350..1100))
  end
end

engaged.each do |c|
  rng.rand(6..14).times do
    add_event(c, "email_open", at: rng.rand(1..45).days.ago, campaign: %w[Weekend tips New routes Member offers].sample(random: rng))
  end
  rng.rand(3..8).times do
    add_event(c, "email_click", at: rng.rand(1..40).days.ago, campaign: %w[Weekend tips New routes].sample(random: rng), url: "https://horizon.example/offers")
  end
  add_event(c, "page_view", at: rng.rand(1..20).days.ago, url: %w[/japan-tours /italy-guides /nz-road-trips /greece-deals].sample(random: rng)) if rng.rand < 0.5
end

buyers.each do |c|
  2.times do
    add_event(
      c,
      "purchase",
      at: rng.rand(10..120).days.ago,
      destination: %w[Japan Italy Thailand France NZ].sample(random: rng),
      style: %w[mid luxury budget].sample(random: rng),
      value: rng.rand(900..4500)
    )
  end
  add_event(c, "page_view", at: rng.rand(1..30).days.ago, url: "/account/trips") if rng.rand < 0.6
end

noise.each do |c|
  add_event(c, "page_view", at: rng.rand(50..120).days.ago, url: %w[/canada-guides /mexico-beaches /spain-cities].sample(random: rng)) if rng.rand < 0.6
  add_event(c, "email_open", at: rng.rand(55..140).days.ago, campaign: "Newsletter") if rng.rand < 0.4
end

puts "Contacts: #{Contact.count}"
puts "Events:   #{Event.count} (page views, email engagement, forms, purchases)"
puts "Run Analyse audience from the app to discover Smart Audiences from HubSpot-style activity."
