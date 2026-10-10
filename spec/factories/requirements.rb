FactoryBot.define do
     factory :requirement do
          sequence(:name) { |n| "Point Type #{n}" }
       description { nil }
       minimum_points { 0 }
       is_active { true }

       trait :inactive do
            is_active { false }
       end
     end
end
