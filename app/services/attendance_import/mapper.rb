module AttendanceImport
     class Mapper
          Row = Struct.new(
               :index, :raw, :email, :checked_in_at, :member, :status, :errors,
               keyword_init: true
          )

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
                    errors = []

                    email = values["email"].to_s.strip.downcase
                    member = email.present? ? Member.find_by(email: email) : nil
                    errors << "No member found for #{email.presence || 'blank email'}" if member.nil?

                    checked_in_at = parse_time(values["checked in"], errors)

                    Row.new(
                         index: index + 2,
                         raw: raw,
                         email: email,
                         checked_in_at: checked_in_at,
                         member: member,
                         status: errors.any? ? :error : :ready,
                         errors: errors
                    )
               end

               def normalized_row(raw)
                    @headers.each_with_index.each_with_object({}) do |(header, i), acc|
                         acc[header.to_s.downcase.strip] = raw[i].to_s
                    end
               end

               def parse_time(value, errors)
                    raw_value = value.to_s.strip
                    if raw_value.empty?
                         errors << "Missing Checked In timestamp"
                         return nil
                    end

                    # Excel datetime cells arrive from roo as ISO strings with a
                    # +00:00 offset that does not reflect the real wall clock.
                    # Reading the components keeps the time shown in Excel
                    # (10:33 PM stays 10:33 PM) instead of letting the offset
                    # shift it into the app zone.
                    if (match = raw_value.match(/\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/))
                         return Time.zone.local(
                              match[1].to_i, match[2].to_i, match[3].to_i,
                              match[4].to_i, match[5].to_i, match[6].to_i
                         )
                    end

                    parsed = Time.zone.parse(raw_value)
                    if parsed.nil?
                         errors << "Could not read Checked In timestamp: #{raw_value.inspect}"
                    end
                    parsed
               rescue ArgumentError, TypeError
                    errors << "Could not read Checked In timestamp: #{raw_value.inspect}"
                    nil
               end
     end
end
