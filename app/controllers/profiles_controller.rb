class ProfilesController < ApplicationController
  def edit
    @member = current_member
  end

  def update
    @member = current_member
    @member.assign_attributes(profile_params)
    @member.profile_completed_at ||= Time.current

    if @member.save(context: :profile)
      redirect_to root_path, notice: "Profile saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Only fields the member may change. Never role_id or points.
  def profile_params
    params.require(:member).permit(:first_name, :last_name,
                                   :pt_school_application_date, :car_pool_status)
  end
end
