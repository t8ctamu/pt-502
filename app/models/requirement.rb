class Requirement < ApplicationRecord
     has_many :events, dependent: :restrict_with_error
  has_many :points, dependent: :restrict_with_error

  scope :active, -> { where(is_active: true) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :minimum_points,
    numericality: { only_integer: true, greater_than_or_equal_to: 0,
                    message: "Enter a whole number of 0 or more" }
end
