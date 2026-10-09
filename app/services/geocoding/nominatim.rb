require "net/http"
require "json"

module Geocoding
  class Error < StandardError; end

  # Thin wrapper over OpenStreetMap's Nominatim. Called server-side so the
  # provider can be swapped (Mapbox, Google, ...) without touching the JS, and
  # so we can send the required User-Agent and cap request volume.
  # Usage policy: https://operations.osmfoundation.org/policies/nominatim/
  class Nominatim
    BASE_URL = "https://nominatim.openstreetmap.org".freeze
    USER_AGENT = ENV.fetch("GEOCODER_USER_AGENT", "EventLocationPicker/1.0 (set GEOCODER_USER_AGENT)").freeze

    def search(query, limit: 6)
      rows = get("/search", q: query, format: "jsonv2", limit: limit)
      Array(rows).filter_map do |row|
        next unless row["lat"] && row["lon"] && row["display_name"]
        { label: row["display_name"], latitude: row["lat"].to_f, longitude: row["lon"].to_f }
      end
    end

    def reverse(latitude, longitude)
      row = get("/reverse", lat: latitude, lon: longitude, format: "jsonv2")
      return nil unless row.is_a?(Hash) && row["display_name"]

      { label: row["display_name"], latitude: latitude.to_f, longitude: longitude.to_f }
    end

    private

    def get(path, params)
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
        http.request(request)
      end
      raise Error, "Geocoder responded with #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError,
           OpenSSL::SSL::SSLError, JSON::ParserError => e
      raise Error, "#{e.class}: #{e.message}"
    end
  end
end
