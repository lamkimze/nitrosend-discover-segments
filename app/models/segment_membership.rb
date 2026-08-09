class SegmentMembership < ApplicationRecord
  belongs_to :segment
  belongs_to :contact

  validates :contact_id, uniqueness: { scope: :segment_id }
end
