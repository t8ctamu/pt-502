# Included by Event.
#
# Event already validates the location name (presence), each coordinate's
# range, and that latitude/longitude come as a pair. This adds the rule from the
# location-picker story: a new or edited event must have a pin, so it can never
# be saved with a missing location.
module EventLocationValidations
     extend ActiveSupport::Concern

  included do
       validate :location_pin_must_be_selected
  end

  private

       def location_pin_must_be_selected
            return unless latitude.nil? && longitude.nil?

         errors.add(:base, "Choose a location on the map before saving.")
       end
end
