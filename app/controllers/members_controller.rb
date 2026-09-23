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
  def member_params
    member_attributes = params.require(:member)

    if member_attributes[:paid_dues].present?
      member_attributes.permit(:paid_dues)
    else
      member_attributes.permit(:points)
    end

  end
end
