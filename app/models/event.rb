class Event < ApplicationRecord
  include EventLocationValidations
  belongs_to :requirement, optional: true
  has_many :attendances, dependent: :destroy
  has_many :members, through: :attendances

  validates :name, :description, :starts_at, :location, presence: true
  validate :ends_at_after_starts_at
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :point_value, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :check_in_radius_meters, numericality: { only_integer: true, greater_than: 0 }
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
      errors.add(:base, "End time must be after the start time")
    end
  end
end
