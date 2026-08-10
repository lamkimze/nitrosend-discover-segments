class Segment < ApplicationRecord
  SOURCES = %w[ai manual system].freeze
  STATUSES = %w[active archived].freeze

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
