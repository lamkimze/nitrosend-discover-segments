class Campaign < ApplicationRecord
  belongs_to :segment

  validates :status, inclusion: { in: %w[draft saved] }

  def draft?
    status == "draft"
  end
end
