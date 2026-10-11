FactoryBot.define do
  factory :member do
    sequence(:email) { |n| "member#{n}@tamu.edu" }
    first_name { "Test" }
    sequence(:last_name) { |n| format("Member%06d", n) }
    role { association :role }
    joined_at { Date.current }
    profile_completed_at { nil }
    paid_dues { false }

    trait :profile_completed do
      profile_completed_at { Time.current }
      expected_graduation_term { "Spring #{Date.current.year + 1}" }
      pt_school_application_date { Date.new(Date.current.year + 1, 6, 1) }
    end

    trait :incomplete_profile do
      profile_completed_at { nil }
    end

    trait :admin do
      role { association :role, :admin }
    end

    trait :manager do
      role { association :role, :manager }
    end

    trait :paid do
      paid_dues { true }
    end
  end
end
