FactoryBot.define do
     factory :semester do
          sequence(:name) { |n| "Semester #{n}" }
       starts_on { 1.year.ago.to_date }
       ends_on   { 6.months.ago.to_date }
     end
end
