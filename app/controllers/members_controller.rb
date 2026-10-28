class MembersController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin, except: :change_role
  before_action :require_manager, only: :change_role

  SORT_KEYS = {
  "id"                  => ->(m) { m.id },
  "role"                => ->(m) { m.role.description },
  "first_name"          => ->(m) { m.first_name.to_s.downcase },
  "last_name"           => ->(m) { m.last_name.to_s.downcase },
  "email"               => ->(m) { m.email.to_s.downcase },
  "joined_at"           => ->(m) { m.joined_at },
  "total"               => ->(m) { m.total_points },
  "expected_graduation" => ->(m) { m.expected_graduation_term.presence },
  "anticipated_cycle"   => ->(m) { m.anticipated_application_cycle },
  "paid_dues"           => ->(m) { m.paid_dues ? 1 : 0 }
}.freeze

def index
  @requirements = Requirement.active.order(:id)
  @removed_members = Member.non_admins.where.not(removed_at: nil).includes(:role).order(:removed_at)

  members = Member.non_admins.active.includes(:role, :point_entries)
                  .order(:last_name, :first_name).to_a
  @members = sort_members(filter_members(members))

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
      if editing_profile
        redirect_to members_path, notice: "#{@member.first_name}'s #{detail} updated."
      else
        # Dues toggle is submitted from the roster; keep the current filters/sort.
        redirect_back_or_to members_path, notice: "#{@member.first_name}'s #{detail} updated."
      end
    elsif editing_profile
      render :edit, status: :unprocessable_entity
    else
      redirect_back_or_to members_path, alert: "Could not update #{@member.first_name}."
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
      return redirect_back_or_to members_path, alert: "Enter a whole number of 0 or more."
    end

    delta = target - member.points_by_requirement[requirement.id].to_i
    return redirect_back_or_to members_path if delta.zero?

    point = member.point_entries.build(
      requirement: requirement,
      point_amount: delta,
      awarded_date: Date.current,   # confirm name in schema.rb
      note: "Adjusted by #{current_member.email}"
    )

    if point.save
      redirect_back_or_to members_path,
        notice: "#{member.first_name}'s #{requirement.name} points set to #{target}."
    else
      redirect_back_or_to members_path, alert: point.errors.full_messages.to_sentence
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

  # Filters use the same Member methods the table displays (points_by_requirement,
  # active_status?, etc.), so a filter can never disagree with what's in a cell.

  def filter_members(members)
    case params[:car_pool]
    when "yes" then members = members.select(&:car_pool_status)
    when "no"  then members = members.reject(&:car_pool_status)
    end

    case params[:status]
    when "active"   then members = members.select { |m| m.active_status? && m.paid_dues }
    when "inactive" then members = members.reject { |m| m.active_status? && m.paid_dues }
    end

    rid = params[:points_requirement_id].to_i
    if %w[zero positive].include?(params[:points_filter]) && @requirements.any? { |r| r.id == rid }
      members = members.select do |m|
        pts = m.points_by_requirement[rid].to_i   # missing entry counts as 0
        params[:points_filter] == "zero" ? pts.zero? : pts.positive?
      end
    end

    members
  end

  def sort_members(members)
    key = params[:sort].to_s
    getter =
      if key.start_with?("req_")
        rid = key.delete_prefix("req_").to_i
        ->(m) { m.points_by_requirement[rid].to_i } if @requirements.any? { |r| r.id == rid }
      else
        SORT_KEYS[key]
      end
    return members unless getter

    with_value, blank = members.partition { |m| !getter.call(m).nil? }
    sorted = with_value.sort_by.with_index { |m, i| [ getter.call(m), i ] }  # index keeps ties stable
    sorted.reverse! if params[:dir] == "desc"
    sorted + blank                                                          # blanks always last
  end
end
