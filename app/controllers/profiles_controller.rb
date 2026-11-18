class ProfilesController < ApplicationController
  def edit
    @member = current_member
  end

  def update
    @member = current_member
    @member.assign_attributes(member_profile_params)
    previous_completion = @member.profile_completed_at
    @member.profile_completed_at ||= Time.current

    if save_member_profile(@member)
      redirect_to root_path, notice: "Profile saved."
    else
      @member.profile_completed_at = previous_completion
      render :edit, status: :unprocessable_entity
    end
  end

  def leave
    if current_member.update(removed_at: Time.current)
      sign_out current_member
      redirect_to root_path, notice: "You have left the organization."
    else
      redirect_to root_path, alert: "Could not leave the organization. Please try again."
    end
  end
end
