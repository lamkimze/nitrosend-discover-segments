class DiscoveryRun < ApplicationRecord
  has_many :segments, dependent: :destroy
  has_many :insights, dependent: :destroy

  validates :status, presence: true

  scope :latest, -> { order(created_at: :desc) }

  def self.current
    latest.first
  end

  def complete?
    status == "complete"
  end
end
