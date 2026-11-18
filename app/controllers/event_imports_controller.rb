require "fileutils"

class EventImportsController < ApplicationController
     before_action :require_completed_profile
  before_action :require_admin
  before_action :load_import_file, only: %i[preview confirm]

  MAX_FILE_BYTES = 10.megabytes
  ALLOWED_EXTENSIONS = %w[.csv .xlsx].freeze

  def new
  end

  def create
       file = params[:file]
    return render_invalid("Please upload a .csv or .xlsx file.") unless valid_file?(file)
    return render_invalid("File is too large (max 10 MB).") if file.size > MAX_FILE_BYTES

    token = SecureRandom.uuid
    path = import_path(token)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, file.read)

    redirect_to preview_event_import_path(token)
  end

  def preview
       parser = EventImport::Parser.new(@path)
       @requirements = Requirement.active.order(:id).to_a
       @other_requirement_id = Requirement.find_by(name: "Other")&.id
       @preview_rows = EventImport::Mapper.new(headers: parser.headers, rows: parser.rows).preview
     rescue StandardError => e
          Rails.logger.error("Event import preview failed: #{e.message}")
       File.delete(@path) if File.exist?(@path)
       redirect_to new_event_import_path, alert: "That file could not be read. Please check the format and try again."
  end

  def confirm
       parser = EventImport::Parser.new(@path)
    rows = EventImport::Mapper.new(headers: parser.headers, rows: parser.rows).preview
    selected_rows = Array(params[:selected_rows]).map(&:to_s)
    rows.each do |row|
         if %i[new update].include?(row.status) && !selected_rows.include?(row.index.to_s)
              row.status = :skip
         end
    end

    result = EventImport::Executor.new(
      rows: rows,
      assignments: assignment_params
    ).call

    File.delete(@path) if File.exist?(@path)

    redirect_to events_path, notice: summary_message(result)
  end

  private

       def valid_file?(file)
            return false unless file.is_a?(ActionDispatch::Http::UploadedFile)
         ALLOWED_EXTENSIONS.include?(File.extname(file.original_filename).downcase)
       end

  def render_invalid(message)
       flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end

  def import_path(token)
       Rails.root.join("tmp", "event_imports", "#{token}#{File.extname(params[:file].original_filename)}").to_s
  end

  def load_import_file
       token = params[:token].to_s
    unless token.match?(/\A[0-9a-f-]{36}\z/)
         return redirect_to new_event_import_path, alert: "Invalid import."
    end
    @path = Dir.glob(Rails.root.join("tmp", "event_imports", "#{token}.*")).first
    unless @path && File.exist?(@path)
         redirect_to new_event_import_path, alert: "Import expired. Please upload again."
    end
  end

def assignment_params
     assignments = params[:assignments]
  return {} unless assignments.respond_to?(:to_unsafe_h)

  assignments.to_unsafe_h.each_with_object({}) do |(row_index, fields), acc|
       next unless fields.is_a?(Hash) || fields.respond_to?(:to_unsafe_h)

    fields = fields.to_unsafe_h if fields.respond_to?(:to_unsafe_h)
    fields = fields.to_h unless fields.is_a?(Hash)

    acc[row_index] = {
      "requirement_id" => fields["requirement_id"],
      "point_value" => fields["point_value"],
      "other_type" => fields["other_type"]
    }
  end
end

     def summary_message(result)
          parts = []
     parts << "#{result.created} event#{'s' if result.created != 1} added"
     parts << "#{result.updated} updated" if result.updated.positive?
     parts << "#{result.skipped} skipped" if result.skipped.positive?
     parts << "#{result.errored.size} had issues" if result.errored.any?

     base = "Import complete: #{parts.join(', ')}."

     if result.missing_coordinates.positive?
          count = result.missing_coordinates
     verb = count == 1 ? "needs" : "need"
     base += " #{count} event#{'s' if count != 1} #{verb} a location pin — open the events list to add one."
     end

     base
     end
end
