FactoryBot.define do
  factory :event do
    name        { "Test Event" }
    description { "A test event" }
    starts_at   { 1.day.from_now }
    ends_at     { 1.day.from_now + 1.hour }
    location    { "Room 101" }
    latitude { 30.6280 }
    longitude { -96.3344 }
  end
end
