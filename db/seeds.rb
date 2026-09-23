%w[Admin Manager Member].each { |r| Role.find_or_create_by!(description: r) }

# Fake sample data: development only, never in production
if Rails.env.development?
  member_role = Role.find_by!(description: "Member")

  [
    # first,    last,      email,                       carpool, points, applying
    [ "Alice",  "Nguyen",  "alice.nguyen@tamu.edu",     true,  12, Date.new(2027, 5, 1) ],
    [ "Ben",    "Ortiz",   "ben.ortiz@tamu.edu",        false,  4, Date.new(2027, 8, 1) ],
    [ "Carla",  "Singh",   "carla.singh@tamu.edu",      true,   9, Date.new(2028, 1, 1) ],
    [ "Derek",  "Johnson", "derek.johnson@tamu.edu",    false,  0, nil ],
    [ "Elena",  "Garcia",  "elena.garcia@tamu.edu",     true,  20, Date.new(2027, 5, 1) ]
  ].each do |first, last, email, carpool, points, applying|
    Member.find_or_create_by!(email: email) do |m|
      m.role                       = member_role
      m.first_name                 = first
      m.last_name                  = last
      m.joined_at                  = Date.current
      m.car_pool_status            = carpool
      m.points                     = points
      m.pt_school_application_date = applying
      m.profile_completed_at       = Time.current
    end
  end
end
