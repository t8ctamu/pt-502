class Member < ApplicationRecord
  ALLOWED_EMAIL_DOMAIN = "@tamu.edu".freeze

  devise :omniauthable, omniauth_providers: [ :google_oauth2 ]

  belongs_to :role
  delegate :admin?, :manager?, to: :role, allow_nil: true

  has_many :rsvps, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :point_entries, class_name: "Point", dependent: :destroy

  scope :admins, -> {
    admin_names = Role::LEVELS.select { |_, lvl| lvl >= 1 }.keys
    joins(:role).where("LOWER(roles.description) IN (?)", admin_names)
  }
  scope :non_admins, -> {
    admin_names = Role::LEVELS.select { |_, lvl| lvl >= 1 }.keys
    joins(:role).where("LOWER(roles.description) NOT IN (?)", admin_names)
  }

  validates :pt_school_application_date, presence: true, on: :profile
  validates :email, presence: true

  def reload(*)
    @points_by_requirement = nil
    super
  end

  def profile_completed?
    profile_completed_at.present?
  end

  def total_points
    point_entries.sum(:point_amount)
  end

  def points_by_requirement
    @points_by_requirement ||= point_entries.group(:requirement_id).sum(:point_amount)
  end

  def requirement_shortfalls
    Requirement.active.where("minimum_points > 0").filter_map do |req|
      needed = req.minimum_points - points_by_requirement.fetch(req.id, 0)
      { requirement: req, needed: needed } if needed > 0
    end
  end

  def total_points_needed
    [ AppSetting.total_points_required - total_points, 0 ].max
  end

  def active_status?
    requirement_shortfalls.empty? && total_points_needed.zero?
  end

  def missing_requirements_text
    parts = requirement_shortfalls.map do |s|
      "needs #{s[:needed]} more #{s[:requirement].name.downcase} point#{'s' if s[:needed] != 1}"
    end

    if total_points_needed.positive?
      parts << "needs #{total_points_needed} more point#{'s' if total_points_needed != 1} in total"
    end

    parts.join(", ")
  end

  def status_label
    active_status? ? "Active" : "Inactive"
  end


  def self.from_google(email:, first_name:, last_name:, uid:, avatar_url:)
    email = email.to_s.downcase.strip
    return nil unless email.end_with?(ALLOWED_EMAIL_DOMAIN)

    member = find_or_initialize_by(email: email)
    member.uid = uid
    member.avatar_url = avatar_url

    if member.new_record?
      member.first_name = first_name.to_s
      member.last_name  = last_name.to_s
      member.role       = Role.find_or_create_by!(description: "Member")
      member.joined_at  = Date.current
    end

    member.save ? member : nil
  end
end
