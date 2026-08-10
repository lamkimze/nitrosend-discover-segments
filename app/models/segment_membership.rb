class SegmentMembership < ApplicationRecord
  belongs_to :contact
  belongs_to :segment

  validates :contact_id, uniqueness: { scope: :segment_id }
end
