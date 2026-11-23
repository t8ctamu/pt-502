class SavedLocation < ApplicationRecord
     has_many :events, dependent: :restrict_with_error

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false, conditions: -> { where(is_saved: true) } }, if: :is_saved?
  validates :latitude, :longitude, presence: true, if: :is_saved?
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :coordinates_provided_together

  scope :reusable, -> { where(is_saved: true) }
  scope :ordered, -> { order(Arel.sql("LOWER(name)")) }

  private

       def coordinates_provided_together
            errors.add(:base, "Provide both latitude and longitude") unless latitude.nil? == longitude.nil?
       end
end
