class MembersController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin

  def index
    @members = Member.includes(:role).order(:last_name, :first_name)
  end

  def update
    member = Member.find(params[:id])
    member.update!(role_id: params.require(:member).permit(:role_id)[:role_id])
    redirect_to members_path, notice: "#{member.first_name}'s role updated."
  end
end