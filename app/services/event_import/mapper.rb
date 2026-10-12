module EventImport
     class Mapper
          Row = Struct.new(
            :index, :raw, :attributes, :status, :errors, :existing_event,
            keyword_init: true
          )

       APPROVED_STATUS = "Approved".freeze

       COLUMN_MAP = {
         "reference" => :external_reference,
         "title" => :name,
         "starts" => :starts_at,
         "ends" => :ends_at,
         "marketing blurb" => :description
       }.freeze

       LOCATION_COLUMNS = [ "location", "location detail" ].freeze

       def initialize(headers:, rows:)
            @headers = headers.map(&:to_s)
         @rows = rows
       end

       def preview
            @preview ||= @rows.each_with_index.map { |raw, i| build_row(i, raw) }
       end

       private

            def build_row(index, raw)
                 values = normalized_row(raw)
              attrs = {}
              errors = []

              COLUMN_MAP.each do |col, field|
                   raw_value = values[col].to_s.strip
                next if raw_value.empty?

                attrs[field] = case field
                when :starts_at, :ends_at then parse_time(raw_value, col, errors)
                else raw_value
                end
              end

              attrs[:location] = build_location(values)
              attrs[:description] = "Event details coming soon." if attrs[:description].blank?

              status = status_for(values, attrs, errors)
              existing = find_existing(attrs[:external_reference])

              status = :update if status == :new && existing

              Row.new(
                index: index + 2,
                raw: raw,
                attributes: attrs,
                status: status,
                errors: errors,
                existing_event: existing
              )
            end

       def normalized_row(raw)
            @headers.each_with_index.each_with_object({}) do |(header, i), acc|
                 key = header.to_s.downcase.strip
              acc[key] = raw[i].to_s
            end
       end

def parse_time(value, column_name, errors)
     parsed = Time.zone.parse(value)
     if parsed.nil?
          errors << "Could not parse #{column_name}: #{value.inspect}"
     end
     parsed
   rescue ArgumentError, TypeError
        errors << "Could not parse #{column_name}: #{value.inspect}"
     nil
end

       def build_location(values)
            parts = LOCATION_COLUMNS.map { |c| values[c].to_s.strip }.reject(&:empty?)
         parts.join(" — ").presence
       end

def status_for(values, attrs, errors)
     errors << "Missing reference" if attrs[:external_reference].blank?
  errors << "Missing title" if attrs[:name].blank?
  errors << "Missing start time" if attrs[:starts_at].blank?
  errors << "Missing location" if attrs[:location].blank?

  return :error if errors.any?

  status_value = values["status"].to_s.strip
  unless status_value.casecmp?(APPROVED_STATUS)
       errors << "Status is '#{status_value.presence || 'blank'}', not Approved"
    return :skip
  end

  :new
end

       def find_existing(reference)
            return nil if reference.blank?
         Event.find_by(external_reference: reference)
       end
     end
end
