FactoryBot.define do
  factory :role do
    description { "Member" }

    initialize_with { Role.find_or_create_by(description: description) }

    trait :admin do
      description { "Admin" }
    end
  end
end