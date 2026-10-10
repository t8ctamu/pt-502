FactoryBot.define do
     factory :event_submission do
          member
       requirement
       name { "Habitat build day" }
       event_date { Date.current - 1 }
       description { "Photo of the group at the site" }
     end
end
