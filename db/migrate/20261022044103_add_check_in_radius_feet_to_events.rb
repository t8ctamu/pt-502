class AddCheckInRadiusFeetToEvents < ActiveRecord::Migration[8.1]
     FEET_PER_METER = 3.28084
  MIN_FEET = 100
  MAX_FEET = 1000

  def up
       add_column :events, :check_in_radius_feet, :integer, default: 250, null: false

    # Count rows whose converted value will be clamped, before we clamp them.
    will_clamp = execute(
      "SELECT COUNT(*) FROM events " \
      "WHERE ROUND(check_in_radius_meters * #{FEET_PER_METER}) < #{MIN_FEET} " \
      "OR ROUND(check_in_radius_meters * #{FEET_PER_METER}) > #{MAX_FEET}"
    ).first["count"]
    puts "check_in_radius_feet backfill: #{will_clamp} row(s) will be clamped into #{MIN_FEET}..#{MAX_FEET}."

    execute(
      "UPDATE events SET check_in_radius_feet = " \
      "GREATEST(#{MIN_FEET}, LEAST(#{MAX_FEET}, ROUND(check_in_radius_meters * #{FEET_PER_METER})))"
    )

    add_check_constraint :events,
      "check_in_radius_feet BETWEEN #{MIN_FEET} AND #{MAX_FEET}",
      name: "events_check_in_radius_feet_range"
  end

  def down
       remove_check_constraint :events, name: "events_check_in_radius_feet_range"
    remove_column :events, :check_in_radius_feet
  end
end
