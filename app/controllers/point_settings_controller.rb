class PointSettingsController < ApplicationController
     before_action :require_completed_profile
  before_action :require_completed_profile
  before_action :require_point_settings_manager

  def show
       @requirements = Requirement.order(:name)
    @app_setting = AppSetting.current
    @new_requirement = Requirement.new
    end

    def add_type
         @new_requirement = Requirement.new(
             name: params[:name].to_s.strip,
             minimum_points: params[:minimum_points].presence || "0"
         )

    if @new_requirement.save
         redirect_to point_settings_path, notice: "Added point type #{@new_requirement.name}."
    else
         @requirements = Requirement.order(:name)
        @app_setting = AppSetting.current
        flash.now[:alert] = "Could not add the point type."
        render :show, status: :unprocessable_entity
    end
    end

  def update
       @requirements = Requirement.order(:name).to_a
       @app_setting = AppSetting.current
       submitted = params.fetch(:requirements, {})

       @requirements.each do |req|
            value = submitted.dig(req.id.to_s, :minimum_points)
         req.minimum_points = value unless value.nil?
       end

       total = params[:total_points_required]
       @app_setting.total_points_required = total unless total.nil?

       # validate every record so each field shows its own error
       all_valid = (@requirements.map(&:valid?) + [ @app_setting.valid? ]).all?

       if all_valid
            ActiveRecord::Base.transaction do
                 @requirements.each(&:save!)
              @app_setting.save!
            end
         redirect_to point_settings_path, notice: "Point requirements saved."
       else
            flash.now[:alert] = "Fix the highlighted fields. No changes were saved."
         render :show, status: :unprocessable_entity
       end
     rescue StandardError => e
          Rails.logger.error("Point settings save failed: #{e.class}: #{e.message}")
       @requirements = Requirement.order(:name)
       @app_setting = AppSetting.current
       flash.now[:alert] = "Changes could not be saved, try again or contact an admin."
       render :show, status: :internal_server_error
  end

    PROTECTED_TYPES = %w[Service Professionalism Other].freeze

    def destroy_type
         requirement = Requirement.find(params[:id])

        if PROTECTED_TYPES.include?(requirement.name)
             redirect_to point_settings_path, alert: "#{requirement.name} is a core type and can't be deleted."
        elsif requirement.destroy
             redirect_to point_settings_path, notice: "Deleted point type #{requirement.name}."
        else
             redirect_to point_settings_path,
             alert: "#{requirement.name} is in use by points or events, so it can't be deleted."
        end
    end

    private

         def require_point_settings_manager
              redirect_to root_path, alert: "Managers only." unless current_member&.manager?
         end
end
