class ApplicationController < ActionController::Base
  include Pagy::Method

  before_action :authenticate_member!
  before_action :ensure_active_member

  def after_sign_in_path_for(member)
    stored_location_for(member) ||
      (member.profile_completed? ? root_path : edit_profile_path)
  end

  private

  def ensure_active_member
    return unless member_signed_in?
    return unless current_member.removed_at.present?

    sign_out current_member
    redirect_to root_path, alert: "Access denied. Your membership has been removed."
  end

  # Shared by self-service profiles and authorized officer profile edits.
  def member_profile_params
    params.require(:member).permit(:first_name, :last_name, :expected_graduation_term,
                                   :pt_school_application_date, :car_pool_status,
                                   :share_phone_number, :phone_visible, :phone_number)
  end

  def save_member_profile(member, context: :profile)
    member.save(context: context)
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotSaved
    member.errors.add(:base, "Your profile could not be saved. Please try again.")
    false
  end

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
