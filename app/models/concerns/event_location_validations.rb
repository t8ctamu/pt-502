# Include in Event:  include EventLocationValidations
#
# An event can never be saved without a readable location name AND a valid
# coordinate pair. Coordinates are set by the map picker, never typed by hand.
module EventLocationValidations
  extend ActiveSupport::Concern

  included do
    validates :latitude, numericality: {
      greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true
    }
    validates :longitude, numericality: {
      greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true
    }
    validate :location_must_be_selected
  end

  private

  def location_must_be_selected
    if location.blank?
      errors.add(:location, "needs a name or address that members will see")
    end

    if latitude.nil? || longitude.nil?
      errors.add(:base, "Choose a location on the map before saving.")
    end
  end
end
