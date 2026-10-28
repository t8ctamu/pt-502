class Member < ApplicationRecord
  ALLOWED_EMAIL_DOMAIN = "@tamu.edu".freeze

  devise :omniauthable, omniauth_providers: [ :google_oauth2 ]

  belongs_to :role
  delegate :admin?, :manager?, to: :role, allow_nil: true
  alias_attribute :share_phone_number, :phone_visible

  has_many :rsvps, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :point_entries, class_name: "Point", dependent: :destroy
  has_many :event_submissions, dependent: :destroy

  scope :admins, -> {
    admin_names = Role::LEVELS.select { |_, lvl| lvl >= 1 }.keys
    joins(:role).where("LOWER(roles.description) IN (?)", admin_names)
  }
  scope :non_admins, -> {
    admin_names = Role::LEVELS.select { |_, lvl| lvl >= 1 }.keys
    joins(:role).where("LOWER(roles.description) NOT IN (?)", admin_names)
  }

  scope :active, -> {
    where(removed_at: nil)
  }

  before_validation :discard_unshared_phone_number

  validates :first_name, :last_name, :expected_graduation_term, presence: true, on: :profile
  validates :expected_graduation_term, format: {
    with: /\A(Spring|Summer|Fall) [1-9]\d{3}\z/,
    message: "must be a Spring, Summer, or Fall term (for example, Spring 2027)"
  }, allow_blank: true
  validates :pt_school_application_date, presence: true, on: :profile
  validate :application_cycle_is_summer, on: :profile
  validate :shared_phone_number_is_valid, on: :profile
  validates :email, presence: true

  def reload(*)
    @points_by_requirement = nil
    super
  end

  def profile_completed?
    profile_completed_at.present?
  end

     def current_point_entries
          semester = AppSetting.current_semester
          return point_entries.none if semester.nil?
          point_entries.where(semester_id: semester.id)
     end

  def anticipated_application_cycle
    "Summer #{pt_school_application_date.year}" if pt_school_application_date.present?
  end

  def shared_phone_number
    phone_number if share_phone_number?
  end

     def total_points
          current_point_entries.sum(:point_amount)
     end

     def points_by_requirement
          @points_by_requirement ||= current_point_entries.group(:requirement_id).sum(:point_amount)
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

  ALLOWED_EXTERNAL_EMAILS = %w[tamupts1@gmail.com].freeze

  def self.from_google(email:, first_name:, last_name:, uid:, avatar_url:)
    email = email.to_s.downcase.strip
    return nil unless email.end_with?(ALLOWED_EMAIL_DOMAIN) || ALLOWED_EXTERNAL_EMAILS.include?(email.to_s.downcase)

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

  private

  def application_cycle_is_summer
    return if pt_school_application_date.blank? || (6..8).cover?(pt_school_application_date.month)

    errors.add(:pt_school_application_date, "must be a summer term. Please choose a summer term")
  end

  def discard_unshared_phone_number
    return unless phone_number_changed? || phone_visible_changed?

    self.phone_number = share_phone_number? ? phone_number&.strip : nil
  end

  def shared_phone_number_is_valid
    return unless share_phone_number?

    number = phone_number.to_s
    return if number.match?(/\A\+?[0-9 ().-]+\z/) && (10..15).cover?(number.count("0-9")) && number.length <= 40

    errors.add(:phone_number, "must be a valid phone number with 10 to 15 digits")
  end
end
