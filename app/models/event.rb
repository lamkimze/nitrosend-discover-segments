class Event < ApplicationRecord
  belongs_to :contact

  TYPES = %w[
    destination_viewed
    product_viewed
    campaign_opened
    campaign_clicked
    purchase
  ].freeze

  validates :event_type, presence: true, inclusion: { in: TYPES }
  validates :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc) }
end
