FactoryBot.define do
  factory :attendance do
    member
    event
    checked_in_at { nil }
    point { nil }

    trait :checked_in do
      checked_in_at { Time.current }
    end
  end
end