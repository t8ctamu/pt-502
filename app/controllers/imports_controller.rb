require "fileutils"

class ImportsController < ApplicationController
     before_action :require_completed_profile
  before_action :require_admin
  before_action :load_import_file, only: %i[preview confirm]

  MAX_FILE_BYTES = 10.megabytes

  def new
  end

  def create
       file = params[:file]
    return render_invalid("Please upload a .csv file.") unless csv?(file)
    return render_invalid("File is too large (max 10 MB).") if file.size > MAX_FILE_BYTES

    token = SecureRandom.uuid
    path = import_path(token)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, file.read)

    redirect_to preview_import_path(token)
  end

  def preview
       parser = MemberImport::Parser.new(@path)
       @headers = parser.headers
       @requirements = Requirement.active.order(:id)
       @mapping = mapping_params.presence ||
                  auto_detect_mapping(@headers, parser.rows.first(5))
       @preview_rows = MemberImport::Mapper.new(rows: parser.rows, mapping: @mapping).preview
     rescue CSV::MalformedCSVError => e
          Rails.logger.error("CSV parse failed: #{e.message}")
       File.delete(@path) if File.exist?(@path)
       redirect_to new_import_path, alert: "That file isn't valid CSV: #{e.message}"
  end

  def confirm
       parser = MemberImport::Parser.new(@path)
    rows = MemberImport::Mapper.new(rows: parser.rows, mapping: mapping_params).preview

    @created = MemberImport::Executor.new(rows).call
    @skipped = rows.count { |r| r.status == :skip }
    @errored = rows.select { |r| r.status == :error }

    File.delete(@path) if File.exist?(@path)
    render :summary
  end

  private

       def csv?(file)
            file.is_a?(ActionDispatch::Http::UploadedFile) &&
              File.extname(file.original_filename).downcase == ".csv"
       end

  def render_invalid(message)
       flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end

  def import_path(token)
       Rails.root.join("tmp", "imports", "#{token}.csv").to_s
  end

  def load_import_file
       token = params[:token].to_s
    unless token.match?(/\A[0-9a-f-]{36}\z/)
         return redirect_to new_import_path, alert: "Invalid import."
    end
    @path = import_path(token)
    unless File.exist?(@path)
         redirect_to new_import_path, alert: "Import expired. Please upload again."
    end
  end

  def mapping_params
       raw = params[:mapping]
    return {} if raw.blank?
    raw.permit(*raw.keys).to_h
  end

  def auto_detect_mapping(headers, sample_rows)
       reqs = Requirement.active.to_a
    headers.each_with_index.to_h do |h, i|
         key = h.to_s.downcase.strip
      field =
        if key.empty?
             blank_header_guess(sample_rows, i)
        else
             case key
             when /email/        then "email"
             when /first.*name/  then "first_name"
             when /last.*name/   then "last_name"
             when /^name$/, /full.*name/ then "full_name"
             when /dues/         then "paid_dues"
             else
                  match = reqs.find { |r| r.name.to_s.downcase == key }
               match ? "requirement:#{match.id}" : "ignore"
             end
        end
      [ i.to_s, field ]
    end
  end

  def blank_header_guess(rows, col_index)
       values = rows.map { |r| r[col_index].to_s.strip }.reject(&:empty?)
    return "ignore" if values.empty?

    looks_like_name = values.all? do |v|
         v.match?(/\A[A-Za-z][A-Za-z\s'.\-\/]+\z/) && v.include?(" ") && !v.include?("@")
    end

    looks_like_name ? "full_name" : "ignore"
  end
end
