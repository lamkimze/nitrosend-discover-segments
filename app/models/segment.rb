class Segment < ApplicationRecord
  SOURCES = %w[ai manual system].freeze
  STATUSES = %w[active archived].freeze

  # Suggested campaign angles — subject + why — so the handoff is visible
  # before the user opens the campaign form.
  ANGLES = {
    "japan" => {
      subject: "Japan, at your pace — curated routes for travellers like you",
      why: "Matches repeated Japan destination interest with recent campaign engagement."
    },
    "luxury" => {
      subject: "Quiet luxury escapes — villas, drivers, and tables worth dressing for",
      why: "High average purchase value and luxury product browsing suggest premium framing."
    },
    "budget" => {
      subject: "Smart travel without the markup — deals matched to how you explore",
      why: "Value destinations and discount engagement call for deal-led creative, not upsell."
    },
    "engaged" => {
      subject: "You’re one of our most curious travellers — here’s what’s next",
      why: "Consistent opens and clicks mean a timely, personal update will land."
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
