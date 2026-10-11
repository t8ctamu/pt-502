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
end
