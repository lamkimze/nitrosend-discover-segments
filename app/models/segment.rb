class Segment < ApplicationRecord
  belongs_to :discovery_run
  has_many :segment_memberships, dependent: :destroy
  has_many :contacts, through: :segment_memberships

  STATUSES = %w[proposed accepted dismissed].freeze
  STRENGTHS = %w[strong moderate emerging].freeze

  validates :name, :status, :strength, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :strength, inclusion: { in: STRENGTHS }

  scope :proposed, -> { where(status: "proposed").order(:position) }
  scope :accepted, -> { where(status: "accepted").order(:position) }
  scope :visible, -> { where(status: %w[proposed accepted]).order(:position) }

  def proposed?
    status == "proposed"
  end

  def accepted?
    status == "accepted"
  end

  def dismissed?
    status == "dismissed"
  end

  def sample_contacts(limit = 5)
    contacts.order(:name).limit(limit)
  end

  def accept!
    update!(status: "accepted")
  end

  def dismiss!
    update!(status: "dismissed")
  end
end
