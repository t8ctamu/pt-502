class AddEventCheckInSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :latitude, :decimal, precision: 10, scale: 6
    add_column :events, :longitude, :decimal, precision: 10, scale: 6
    add_column :events, :check_in_radius_meters, :integer, default: 100, null: false
    add_column :events, :point_value, :integer, default: 1, null: false
    add_column :attendances, :points_awarded, :integer, default: 0, null: false
    add_check_constraint :events, "point_value >= 0", name: "events_nonnegative_points"
    add_check_constraint :events, "check_in_radius_meters > 0", name: "events_positive_radius"
  end
end
