class RemoveCheckInRadiusMetersFromEvents < ActiveRecord::Migration[8.1]
     def up
          remove_check_constraint :events, name: "events_positive_radius"
       remove_column :events, :check_in_radius_meters
     end

  def down
       add_column :events, :check_in_radius_meters, :integer, default: 100, null: false
    execute(
      "UPDATE events SET check_in_radius_meters = GREATEST(1, ROUND(check_in_radius_feet * 0.3048))"
    )
    add_check_constraint :events,
      "check_in_radius_meters > 0",
      name: "events_positive_radius"
  end
end
