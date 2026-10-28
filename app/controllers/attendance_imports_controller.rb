require "fileutils"

class AttendanceImportsController < ApplicationController
     before_action :require_completed_profile
     before_action :require_admin

     ALLOWED_EXTENSIONS = %w[.csv .xlsx].freeze
     REQUIRED_COLUMNS = [ "checked in", "email" ].freeze
     SESSION_KEY = :attendance_import_result

     def new
          @events = recent_and_upcoming_events
          @search_results = search_events(params[:q]) if params[:q].present?
     end

     def upload
          @event = Event.find(params[:event_id])
     end

     def create
          @event = Event.find(params[:event_id])
          file = params[:file]

          return render_invalid("Please upload a .csv or .xlsx file.") unless valid_file?(file)

          path = write_temp_file(file)
          parser = AttendanceImport::Parser.new(path)

          missing = missing_columns(parser.headers)
          if missing.any?
               return render_invalid("The file is missing required column#{"s" if missing.size != 1}: #{missing.join(', ')}.")
          end

          rows = AttendanceImport::Mapper.new(headers: parser.headers, rows: parser.rows).preview
          result = AttendanceImport::Executor.new(rows: rows, event: @event).call

          session[SESSION_KEY] = {
               event_id: @event.id,
               saved: result.saved,
               errors: result.errors.map do |row|
                    { row: row.index, email: row.email, reason: row.errors.join("; ") }
               end
          }

          redirect_to results_attendance_imports_path
     rescue StandardError => e
          Rails.logger.error("Attendance import failed: #{e.message}")
          render_invalid("That file could not be read. Please check the format and try again.")
     ensure
          File.delete(path) if path && File.exist?(path)
     end

     def results
          @result = session.delete(SESSION_KEY)&.with_indifferent_access
          return redirect_to new_attendance_import_path, alert: "No recent import to show." if @result.blank?

          @event = Event.find_by(id: @result[:event_id])
     end

     private

          def recent_and_upcoming_events
               Event.where("starts_at >= ? OR starts_at >= ?", 120.days.ago, Time.current)
                    .order(starts_at: :desc)
          end

          def search_events(query)
               Event.where("name ILIKE ?", "%#{query}%").order(starts_at: :desc)
          end

          def valid_file?(file)
               file.is_a?(ActionDispatch::Http::UploadedFile) &&
                    ALLOWED_EXTENSIONS.include?(File.extname(file.original_filename).downcase)
          end

          def write_temp_file(file)
               token = SecureRandom.uuid
               path = Rails.root.join("tmp", "attendance_imports", "#{token}#{File.extname(file.original_filename).downcase}").to_s
               FileUtils.mkdir_p(File.dirname(path))
               File.binwrite(path, file.read)
               path
          end

          def missing_columns(headers)
               normalized = headers.map { |h| h.to_s.downcase.strip }
               REQUIRED_COLUMNS.reject { |col| normalized.include?(col) }
          end

          def render_invalid(message)
               flash.now[:alert] = message
               @event = Event.find_by(id: params[:event_id])
               render :upload, status: :unprocessable_content
          end
end
