class Point < ApplicationRecord
  belongs_to :member
  belongs_to :requirement
  has_one :attendance, dependent: :nullify

  validates :awarded_date, presence: true
  validates :point_amount, numericality: { only_integer: true }
end