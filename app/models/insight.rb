class Insight < ApplicationRecord
  belongs_to :discovery_run

  validates :body, :kind, presence: true

  scope :ordered, -> { order(:position) }
end
