FactoryBot.define do
  factory :role do
    description { "Member" }
    # Role descriptions are unique, so reuse an existing row instead of failing
    initialize_with { Role.find_or_create_by(description: description) }

    trait :admin do
      description { "Admin" }
    end

    trait :manager do
      description { "Manager" }
    end
  end
end
