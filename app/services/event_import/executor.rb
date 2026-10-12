require "cgi"

module EventImport
     class Executor
          Result = Struct.new(:created, :updated, :skipped, :errored, :missing_coordinates, keyword_init: true)
def initialize(rows:, assignments:)
     @rows = rows
  @assignments = (assignments || {}).transform_keys(&:to_i)
                                  .transform_values { |v| v.respond_to?(:symbolize_keys) ? v.symbolize_keys : v }
end

def call
     created = 0
  updated = 0
  skipped = 0
  missing_coordinates = 0
  errored = []

  Event.transaction do
       @rows.each do |row|
            case row.status
            when :skip
                 skipped += 1
            when :error
                 errored << row
            when :new
                 event = create_event(row)
              created += 1
              missing_coordinates += 1 if event.latitude.nil?
            when :update
                 event = update_event(row)
              updated += 1
              missing_coordinates += 1 if event.latitude.nil?
            end
       end
  end

  Result.new(
    created: created,
    updated: updated,
    skipped: skipped,
    errored: errored,
    missing_coordinates: missing_coordinates
  )
end

       private

            def create_event(row)
                 attrs = event_attributes(row).merge(assignment_for(row))
            Event.create!(attrs.merge(geocode_coordinates(attrs[:location])))
            end


            def geocode_coordinates(location)
                 return {} if location.blank?

                 results = Geocoding::Nominatim.new.search(location)
                 return {} if results.empty?

                 top = results.first
                 { latitude: top[:latitude], longitude: top[:longitude] }
                 rescue Geocoding::Error => e
                      Rails.logger.warn("Geocoding failed for #{location.inspect}: #{e.message}")
                 {}
            end

            def update_event(row)
                 row.existing_event.update!(event_attributes(row))
            row.existing_event
            end

       def event_attributes(row)
            attrs = row.attributes.dup
         attrs[:description] = CGI.unescapeHTML(attrs[:description].to_s)
         attrs
       end

       def assignment_for(row)
            assignment = @assignments[row.index] || {}
         {
           requirement_id: assignment[:requirement_id].presence,
           point_value: (assignment[:point_value].presence || 1).to_i,
           other_type: assignment[:other_type].presence
         }.compact
       end
     end
end
