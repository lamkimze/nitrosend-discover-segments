class Contact < ApplicationRecord
  has_many :segment_memberships, dependent: :destroy
  has_many :segments, through: :segment_memberships

  TRIP_STYLES = %w[luxury budget family adventure].freeze
  DESTINATIONS = %w[Japan Italy New\ Zealand Greece Portugal Vietnam].freeze
  SPEND_BANDS = %w[low mid high].freeze

  validates :email, :name, presence: true
  validates :email, uniqueness: true

  def initials
    name.split.map { |part| part[0] }.first(2).join.upcase
  end

  def engagement_label
    case engagement_score
    when 80..100 then "Highly engaged"
    when 50...80 then "Active"
    when 25...50 then "Warming up"
    else "Quiet"
    end
  end
end
