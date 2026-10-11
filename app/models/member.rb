class Member < ApplicationRecord
  ALLOWED_EMAIL_DOMAIN = "@tamu.edu".freeze

  devise :omniauthable, omniauth_providers: [ :google_oauth2 ]

  belongs_to :role
  has_many :rsvps, dependent: :destroy
  has_many :attendances, dependent: :destroy

  before_validation :discard_unshared_phone_number

  validates :first_name, :last_name, :expected_graduation_term, presence: true, on: :profile
  validates :expected_graduation_term, format: {
    with: /\A(Spring|Summer|Fall) [1-9]\d{3}\z/,
    message: "must be a Spring, Summer, or Fall term (for example, Spring 2027)"
  }, allow_blank: true
  validates :pt_school_application_date, presence: true, on: :profile
  validate :application_cycle_is_summer, on: :profile
  validate :shared_phone_number_is_valid
  validates :email, presence: true

  def profile_completed?
    profile_completed_at.present?
  end

  def admin?
    role.present? && role.description.casecmp?("admin")
  end

  def anticipated_application_cycle
    "Summer #{pt_school_application_date.year}" if pt_school_application_date.present?
  end

  def shared_phone_number
    phone_number if share_phone_number?
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

  private

  def application_cycle_is_summer
    return if pt_school_application_date.blank? || (6..8).cover?(pt_school_application_date.month)

    errors.add(:pt_school_application_date, "must be a summer term. Please choose a summer term")
  end

  def discard_unshared_phone_number
    self.phone_number = share_phone_number? ? phone_number&.strip : nil
  end

  def shared_phone_number_is_valid
    return unless share_phone_number?

    number = phone_number.to_s
    return if number.match?(/\A\+?[0-9 ().-]+\z/) && (10..15).cover?(number.count("0-9")) && number.length <= 40

    errors.add(:phone_number, "must be a valid phone number with 10 to 15 digits")
  end
end
