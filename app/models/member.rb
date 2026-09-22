class Member < ApplicationRecord
  ALLOWED_EMAIL_DOMAIN = "@tamu.edu".freeze

  devise :omniauthable, omniauth_providers: [ :google_oauth2 ]

  belongs_to :role
  has_many :rsvps, dependent: :destroy
  has_many :attendances, dependent: :destroy

  validates :pt_school_application_date, presence: true, on: :profile
  validates :email, presence: true

  def profile_completed?
    profile_completed_at.present?
  end

  def admin?
    role.present? && role.description.casecmp?("admin")
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
