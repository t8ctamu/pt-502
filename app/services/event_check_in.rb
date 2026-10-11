class EventCheckIn
  class Rejected < StandardError; end

  EARTH_RADIUS_METERS = 6_371_000.0

  def self.call(member:, event:, latitude:, longitude:)
    new.call(member: member, event: event, latitude: latitude, longitude: longitude)
  end

  def call(member:, event:, latitude:, longitude:)
    raise Rejected, "Please sign in before checking in." unless member&.persisted?

    # Serializing check-ins for this member protects both duplicate scans and
    # simultaneous point awards from different events.
    member.with_lock do
      attendance = Attendance.find_or_initialize_by(member: member, event: event)
      raise Rejected, "You have already checked in to this event." if attendance.checked_in_at?

      raise Rejected, "Check-in is not configured for this event yet." unless event.check_in_configured?

      lat = coordinate(latitude, -90..90)
      lon = coordinate(longitude, -180..180)
      if distance_meters(event.latitude.to_f, event.longitude.to_f, lat, lon) > event.check_in_radius_meters
        raise Rejected, "You are not nearby. Move closer to the event and try again."
      end

      point = nil
      if event.requirement && event.point_value.to_i > 0
        point = member.point_entries.create!(
          requirement: event.requirement,
          point_amount: event.point_value.to_i,
          awarded_date: Date.current,
          note: "Checked in: #{event.name}"
        )
      end

      attendance.update!(checked_in_at: Time.current, point: point)
      attendance
    end
  end

  private

  def coordinate(value, range)
    number = Float(value)
    raise ArgumentError unless number.finite? && range.cover?(number)

    number
  rescue ArgumentError, TypeError
    raise Rejected, "A valid location is required. Allow location access and try again."
  end

  def distance_meters(lat1, lon1, lat2, lon2)
    radians = Math::PI / 180
    a = Math.sin((lat2 - lat1) * radians / 2)**2 +
      Math.cos(lat1 * radians) * Math.cos(lat2 * radians) * Math.sin((lon2 - lon1) * radians / 2)**2
    2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(a.clamp(0.0, 1.0)))
  end
end
