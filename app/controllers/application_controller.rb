class ApplicationController < ActionController::Base
  before_action :authenticate_member!

  def after_sign_in_path_for(member)
    stored_location_for(member) ||
      (member.profile_completed? ? root_path : edit_profile_path)
  end

  private

  def require_completed_profile
    return if current_member.profile_completed?
    redirect_to edit_profile_path, alert: "Please finish your profile first."
  end

  def require_admin
    return if current_member&.admin?
    redirect_to root_path, alert: "You're not authorized to view that page."
  end
end
