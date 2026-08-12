class Segment < ApplicationRecord
  SOURCES = %w[ai manual system].freeze
  STATUSES = %w[active archived].freeze

  # Suggested campaign angles — subject + why — so the handoff is visible
  # before the user opens the campaign form.
  ANGLES = {
    "japan" => {
      subject: "Japan, at your pace — curated routes for travellers like you",
      why: "Repeated Japan page views and related email clicks in HubSpot activity."
    },
    "luxury" => {
      subject: "Quiet luxury escapes — villas, drivers, and tables worth dressing for",
      why: "High purchase value plus luxury page / CTA engagement from CRM data."
    },
    "budget" => {
      subject: "Smart travel without the markup — deals matched to how you explore",
      why: "Value destination pages and deal CTAs call for deal-led creative, not upsell."
    },
    "engaged" => {
      subject: "You’re one of our most curious travellers — here’s what’s next",
      why: "Consistent HubSpot email opens and clicks mean a timely update will land."
    },
    "frequent" => {
      subject: "Welcome back — trips tailored to how you’ve travelled with us",
      why: "Multiple purchases on record make a loyalty / upsell angle natural."
    },
    "dormant" => {
      subject: "Still dreaming of the next trip? Here’s a gentle nudge",
      why: "Low recent website and email activity — re-engagement over hard sell."
    }
  }.freeze

  has_many :segment_memberships, dependent: :destroy
  has_many :contacts, through: :segment_memberships
  has_many :campaigns, dependent: :destroy

  validates :name, presence: true
  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }

  before_validation :ensure_slug, on: :create

  scope :active, -> { where(status: "active").order(confidence_score: :desc, name: :asc) }

  def refresh_contact_count!
    update!(contact_count: segment_memberships.count)
  end

  def archive!
    update!(status: "archived")
  end

  def campaign_angle
    key = ANGLES.keys.find { |k| slug.to_s.include?(k) }
    ANGLES.fetch(key) do
      {
        subject: "A trip shaped around how you travel",
        why: "Built from the behaviours that defined this audience."
      }
    end
  end

  private

  def ensure_slug
    return if slug.present?

    base = name.to_s.parameterize.presence || "audience"
    candidate = base
    n = 2
    while Segment.exists?(slug: candidate)
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end
end
