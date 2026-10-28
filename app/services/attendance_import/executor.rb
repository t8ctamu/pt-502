module AttendanceImport
     class Executor
          Result = Struct.new(:saved, :errors, keyword_init: true)

          def initialize(rows:, event:)
               @rows = rows
               @event = event
          end

          def call
               saved = 0
               errors = []

               # Deliberately NOT wrapped in a transaction: this import is
               # intentionally partial. A bad row must not roll back the valid
               # rows that already saved. EventCheckIn handles its own locking
               # and writes, so each successful row commits on its own.
               @rows.each do |row|
                    if row.status == :error
                         errors << row
                         next
                    end

                    begin
                         EventCheckIn.call(
                              member: row.member,
                              event: @event,
                              skip_distance: true,
                              checked_in_at: row.checked_in_at
                         )
                         saved += 1
                    rescue EventCheckIn::Rejected => e
                         # Covers already-checked-in (re-upload and in-file
                         # duplicates) and a not-configured event. These are
                         # row-level problems, so record and continue.
                         row.errors << e.message
                         errors << row
                    end
               end

               Result.new(saved: saved, errors: errors)
          end
     end
end
