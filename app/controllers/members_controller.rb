class MembersController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin, except: %i[change_role remove restore]
  before_action :require_manager, only: %i[change_role remove restore]

  def index
    @members = Member.non_admins.active.includes(:role).order(:last_name, :first_name)
    @removed_members = Member.non_admins.where.not(removed_at: nil).includes(:role).order(:removed_at)
    @requirements = Requirement.active.order(:id)

    @admins = nil
    @admins_error = nil

    if current_member.admin?
      begin
        @admins = Member.admins.active.includes(:role).order(:last_name, :first_name)
      rescue StandardError => e
        Rails.logger.error("Admins table failed to load: #{e.message}")
        @admins_error = "Admins could not be loaded, try again later."
      end
    end
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

  def set_points
    member = Member.find(params[:id])
    requirement = Requirement.active.find_by(id: params[:requirement_id])
    target = Integer(params[:total].to_s, exception: false)

    if requirement.nil? || target.nil? || target.negative?
      return redirect_to members_path, alert: "Enter a whole number of 0 or more."
    end

    delta = target - member.points_by_requirement[requirement.id].to_i
    return redirect_to members_path if delta.zero?

    point = member.point_entries.build(
      requirement: requirement,
      point_amount: delta,
      awarded_date: Date.current,   # confirm name in schema.rb
      note: "Adjusted by #{current_member.email}"
    )

    if point.save
      redirect_to members_path,
        notice: "#{member.first_name}'s #{requirement.name} points set to #{target}."
    else
      redirect_to members_path, alert: point.errors.full_messages.to_sentence
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

  def remove
    member = Member.find(params[:id])

    if member == current_member
      return redirect_to members_path, alert: "You cannot remove yourself."
    end

    if member.manager?
      return redirect_to members_path, alert: "You cannot remove a Manager."
    end

    if member.update(removed_at: Time.current)
      redirect_to members_path, notice: "#{member.first_name} removed from the roster."
    else
      redirect_to members_path, alert: "Could not remove #{member.first_name}."
    end
  end

  def restore
    member = Member.find(params[:id])

    if member.update(removed_at: nil)
      redirect_to members_path, notice: "#{member.first_name} restored to the roster."
    else
      redirect_to members_path, alert: "Could not restore #{member.first_name}."
    end
  end

  private

  # Members control their own phone number and sharing consent.
  def member_params
    member_profile_params.except(:phone_number, :share_phone_number, :phone_visible)
                         .merge(params.require(:member).permit(:paid_dues))
  end
end
