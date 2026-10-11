class MembersController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin

  def index
    @members = Member.includes(:role).order(:last_name, :first_name)
  end

  def update
    @member = Member.find(params[:id])
    attributes = member_params
    editing_profile = attributes.except(:paid_dues).present?
    @member.assign_attributes(attributes)
    @member.profile_completed_at ||= Time.current if editing_profile

    if save_member_profile(@member, context: editing_profile ? :profile : nil)
      detail = editing_profile ? "profile" : "dues"
      redirect_to members_path, notice: "#{@member.first_name}'s #{detail} updated."
    elsif editing_profile
      render :edit, status: :unprocessable_entity
    else
      redirect_to members_path, alert: "Could not update #{@member.first_name}."
    end
  end

  def edit
    @member = Member.find(params[:id])
  end

  private

  # Members control their own phone number and sharing consent.
  def member_params
    member_profile_params.except(:phone_number, :share_phone_number)
                         .merge(params.require(:member).permit(:paid_dues))
  end
end
