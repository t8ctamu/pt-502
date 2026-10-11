class ProfilesController < ApplicationController
  def edit
    @member = current_member
  end

  def update
    @member = current_member
    @member.assign_attributes(member_profile_params)
    @member.profile_completed_at ||= Time.current

    if @member.save(context: :profile)
      redirect_to root_path, notice: "Profile saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

end
