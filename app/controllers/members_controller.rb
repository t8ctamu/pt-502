class MembersController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin

  def index
    @members = Member.includes(:role).order(:last_name, :first_name)
  end

  def update
    member = Member.find(params[:id])

    if member.update(member_params)
      redirect_to members_path, notice: "#{member.first_name}'s dues updated."
    else
      redirect_to members_path, alert: "Could not update #{member.first_name}."
    end
  end

  private

  # Only the fields admins are allowed to change from the dashboard
  def member_params
    params.require(:member).permit(:paid_dues, :points)
  end
end
