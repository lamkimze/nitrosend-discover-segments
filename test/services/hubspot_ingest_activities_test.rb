# frozen_string_literal: true

require "test_helper"

class HubspotIngestActivitiesTest < ActiveSupport::TestCase
  test "ingests HubSpot-shaped page views and email events" do
    contact = Contact.create!(email: "john@example.com", first_name: "John", last_name: "Example", source: "hubspot")

    created = Hubspot::IngestActivities.call(
      contact: contact,
      activities: [
        { "type" => "PAGE_VIEW", "url" => "/japan-trips", "timestamp" => "2026-08-12T10:00:00Z" },
        { "type" => "PAGE_VIEW", "url" => "/tokyo-hotels", "timestamp" => "2026-08-12T10:03:00Z" },
        { "type" => "FORM_SUBMISSION", "form" => "Japan trip enquiry", "timestamp" => "2026-08-12T10:05:00Z" }
      ],
      email_events: [
        { "type" => "OPEN", "campaign" => "Japan Travel Deals", "timestamp" => "2026-08-12T09:00:00Z" },
        { "type" => "CLICK", "url" => "https://example.com/japan-packages", "campaign" => "Japan Travel Deals", "timestamp" => "2026-08-12T09:01:00Z" }
      ]
    )

    assert_equal 5, created
    assert_equal 2, contact.events.where(event_type: "page_view").count
    assert_equal 1, contact.events.where(event_type: "email_open").count
    assert_equal 1, contact.events.where(event_type: "email_click").count
    assert_equal 1, contact.events.where(event_type: "form_submission").count

    profile = Segmentation::BuildCustomerProfile.call(contact.reload)
    assert_includes profile[:pages_visited], "/japan-trips"
    assert_includes profile[:page_interests], "Japan"
  end
end
