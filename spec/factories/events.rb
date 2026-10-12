FactoryBot.define do
  factory :event do
    sequence(:name) { |n| "Event #{n}" }
    location { "MSC" }
    description { "A test event" }
    starts_at   { 1.day.from_now }
    ends_at     { 1.day.from_now + 1.hour }
    latitude    { 30.6280 }
    longitude   { -96.3344 }
    point_value { 1 }
    requirement { nil }

    # Kept so specs on main that use `create(:event, :check_in_ready)` still work.
    # Coordinates are now always set, so this only adds the radius.
    trait :check_in_ready do
      check_in_radius_meters { 100 }
    end

    trait :with_reference do
      sequence(:external_reference) { |n| "EVN-TEST-#{n}" }
    end
  end
end
