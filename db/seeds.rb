semester = Semester.find_or_create_by!(name: "Fall 2026") do |s|
  s.starts_on = Date.new(2026, 8, 1)
  s.ends_on   = Date.new(2026, 12, 31)
end

AppSetting.current.update!(current_semester: semester)

%w[Admin Manager Member].each { |r| Role.find_or_create_by!(description: r) }

# Real configuration: needed in every environment
[
  [ "Service", 1 ],
  [ "Professionalism", 1 ],
  [ "Other", 0 ]
].each do |name, min|
  Requirement.find_or_create_by!(name: name) { |r| r.minimum_points = min }
end

# Makes sure the total-points setting row exists (defaults to 7)
AppSetting.current

# First manager, so someone can reach Point settings in every environment
manager_role = Role.find_by!(description: "Manager")

owner = Member.find_or_initialize_by(email: "lukechambers0217@tamu.edu")
owner.role = manager_role unless owner.manager?
owner.first_name           ||= "Luke"
owner.last_name            ||= "Chambers"
owner.joined_at            ||= Date.current
owner.profile_completed_at ||= Time.current
owner.save!

admin2  = Member.find_or_initialize_by(email: "balarson@tamu.edu")
admin2.role = manager_role unless admin2.manager?
admin2.first_name           ||= "Brendan"
admin2.last_name            ||= "Larson"
admin2.joined_at            ||= Date.current
admin2.profile_completed_at ||= Time.current
admin2.save!

if Rails.env.development?
  member_role = Role.find_by!(description: "Member")
  service     = Requirement.find_by!(name: "Service")

  [
    # first,    last,      email,                       carpool, points, applying
    [ "Alice",  "Nguyen",  "alice.nguyen@tamu.edu",     true,  12, Date.new(2027, 5, 1) ],
    [ "Ben",    "Ortiz",   "ben.ortiz@tamu.edu",        false,  4, Date.new(2027, 8, 1) ],
    [ "Carla",  "Singh",   "carla.singh@tamu.edu",      true,   9, Date.new(2028, 1, 1) ],
    [ "Derek",  "Johnson", "derek.johnson@tamu.edu",    false,  0, nil ],
    [ "Elena",  "Garcia",  "elena.garcia@tamu.edu",     true,  20, Date.new(2027, 5, 1) ]
  ].each do |first, last, email, carpool, points, applying|
    member = Member.find_or_create_by!(email: email) do |m|
      m.role                       = member_role
      m.first_name                 = first
      m.last_name                  = last
      m.joined_at                  = Date.current
      m.car_pool_status            = carpool
      m.pt_school_application_date = applying
      m.profile_completed_at       = Time.current
    end

    # Sample points go in the ledger (all Service, just so there is data to look at)
    if points > 0 && member.point_entries.none?
      member.point_entries.create!(requirement: service, point_amount: points,
        awarded_date: Date.current, note: "Sample data")
    end
  end
end
