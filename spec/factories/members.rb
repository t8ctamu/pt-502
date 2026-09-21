FactoryBot.define do
  factory :member do
    sequence(:email)      { |n| "member#{n}#{Member::ALLOWED_EMAIL_DOMAIN}" }
    sequence(:uid)        { |n| "uid-#{n}" }
    sequence(:first_name) { |n| "First#{n}" }
    sequence(:last_name)  { |n| "Last#{n}" }
    avatar_url { "https://example.com/avatar.png" }
    joined_at  { Date.current }
    role

    trait :profile_completed do
      profile_completed_at { Time.current }
      pt_school_application_date { Date.current }
    end

    trait :admin do
      association :role, :admin
    end
  end
end
