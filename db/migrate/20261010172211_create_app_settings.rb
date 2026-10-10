class CreateAppSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :app_settings do |t|
      t.integer :total_points_required, null: false, default: 7
      t.timestamps
    end
    add_check_constraint :app_settings, "total_points_required >= 0",
                         name: "app_settings_total_nonnegative"
  end
end