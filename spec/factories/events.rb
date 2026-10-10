FactoryBot.define do
  factory :event do
    sequence(:name) { |n| "Event #{n}" }
    location { "MSC" }
    description { "A test event" }
    starts_at { 1.day.from_now }
    point_value { 1 }
    requirement { nil }

    # Events start without check-in coordinates, like in the app
    trait :check_in_ready do
      latitude { 30.6280 }
      longitude { -96.3344 }
      check_in_radius_meters { 100 }
    end
  end
end