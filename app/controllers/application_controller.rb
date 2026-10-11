class ApplicationController < ActionController::Base
  before_action :authenticate_member!

  def after_sign_in_path_for(member)
    stored_location_for(member) ||
      (member.profile_completed? ? root_path : edit_profile_path)
  end

  private

  # Shared by self-service profiles and authorized officer profile edits.
  def member_profile_params
    params.require(:member).permit(:first_name, :last_name, :expected_graduation_term,
                                   :pt_school_application_date, :car_pool_status,
                                   :share_phone_number, :phone_number)
  end

  def require_completed_profile
    return if current_member.profile_completed?
    redirect_to edit_profile_path, alert: "Please finish your profile first."
  end

  def require_admin
    return if current_member&.admin?
    redirect_to root_path, alert: "You're not authorized to view that page."
  end
end
