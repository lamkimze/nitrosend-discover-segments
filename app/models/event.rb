class Event < ApplicationRecord
  belongs_to :contact

  # HubSpot-style activity types businesses already collect via tracking + CRM.
  # Product-analytics events (in-app feature usage) are intentionally out of scope.
  TYPES = %w[
    page_view
    email_open
    email_click
    form_submission
    cta_click
    purchase
  ].freeze

  LABELS = {
    "page_view" => "Page view",
    "email_open" => "Email open",
    "email_click" => "Email click",
    "form_submission" => "Form submission",
    "cta_click" => "CTA click",
    "purchase" => "Purchase"
  }.freeze

  validates :event_type, presence: true, inclusion: { in: TYPES }
  validates :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc) }

  def label
    LABELS.fetch(event_type, event_type.humanize)
  end

  def summary
    meta = metadata || {}
    case event_type
    when "page_view"
      meta["url"].presence || meta["title"].presence || "Website page"
    when "email_open"
      meta["campaign"].presence || "Email campaign"
    when "email_click"
      [ meta["campaign"], meta["url"] ].compact.first || "Email link"
    when "form_submission"
      meta["form"].presence || "Form"
    when "cta_click"
      meta["cta"].presence || meta["url"].presence || "CTA"
    when "purchase"
      parts = [ meta["destination"], meta["style"] ].compact
      parts.any? ? "#{parts.join(' · ')} ($#{meta['value'].to_i})" : "Purchase"
    else
      label
    end
  end
end
