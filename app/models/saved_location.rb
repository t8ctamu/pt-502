class SavedLocation < ApplicationRecord
     validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :latitude, presence: true,
    numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  scope :ordered, -> { order(Arel.sql("LOWER(name)")) }
end
