class ApplicationController < ActionController::Base
  include Pagy::Method

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

  def require_manager
    return if current_member&.manager?
    redirect_to root_path, alert: "You're not authorized to change roles."
  end
end
