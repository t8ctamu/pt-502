FactoryBot.define do
  factory :point do
    member
    requirement
    awarded_date { Date.current }
    point_amount { 1 }
    note { "Test award" }
  end
end
