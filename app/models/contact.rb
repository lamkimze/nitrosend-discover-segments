class Contact < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :segment_memberships, dependent: :destroy
  has_many :segments, through: :segment_memberships

  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end
end
