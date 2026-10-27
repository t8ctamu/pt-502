class Event < ApplicationRecord
  belongs_to :requirement, optional: true
  has_many :attendances, dependent: :destroy
  has_many :members, through: :attendances

  CHECK_IN_RADIUS_FEET_RANGE = 100..1000
  CHECK_IN_RADIUS_FEET_BLANK_MESSAGE = "Enter a proximity in feet.".freeze
  CHECK_IN_RADIUS_FEET_WHOLE_NUMBER_MESSAGE = "Enter a whole number of feet.".freeze
  CHECK_IN_RADIUS_FEET_RANGE_MESSAGE = "Enter a proximity between 100 and 1,000 feet.".freeze

  validates :name, :description, :starts_at, :location, presence: true
  validate :ends_at_after_starts_at
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :point_value, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :check_in_radius_feet, presence: { message: CHECK_IN_RADIUS_FEET_BLANK_MESSAGE }
  validates :check_in_radius_feet,
    numericality: { only_integer: true, allow_nil: true, message: CHECK_IN_RADIUS_FEET_WHOLE_NUMBER_MESSAGE }
  validates :check_in_radius_feet,
    numericality: { in: CHECK_IN_RADIUS_FEET_RANGE, allow_nil: true, message: CHECK_IN_RADIUS_FEET_RANGE_MESSAGE }
  validate :coordinates_provided_together

  before_validation { self.other_type = nil unless requirement&.name == "Other" }
  validates :other_type, presence: { message: "is required when the point type is Other" },
                        if: -> { requirement&.name == "Other" }
  def check_in_configured?
    latitude.present? && longitude.present?
  end

  private

  def coordinates_provided_together
    return if latitude.nil? == longitude.nil?

    errors.add(:base, "Provide both latitude and longitude")
  end

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    if ends_at <= starts_at
      errors.add(:ends_at, "must be after the start time")
    end
  end
end
