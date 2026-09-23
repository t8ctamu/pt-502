class MembersController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin, except: :change_role
  before_action :require_manager, only: :change_role

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

  def change_role
    member = Member.find(params[:id])

    if member == current_member
      return redirect_to members_path, alert: "You cannot change your own role."
    end

    if member.manager?
      return redirect_to members_path, alert: "You cannot change a Manager's role."
    end

    target_role = Role.all.find { |r| r.description.to_s.casecmp?(params[:role].to_s) }
    allowed = %w[member admin]

    unless target_role && allowed.include?(target_role.description.to_s.downcase)
      return redirect_to members_path, alert: "Invalid role change."
    end

    if member.update(role: target_role)
      redirect_to members_path, notice: "#{member.first_name} is now #{target_role.description}."
    else
      redirect_to members_path, alert: "Could not change #{member.first_name}'s role."
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
