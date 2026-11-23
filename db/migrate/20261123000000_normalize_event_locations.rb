class NormalizeEventLocations < ActiveRecord::Migration[8.1]
     def up
          add_column :saved_locations, :is_saved, :boolean, default: true, null: false
       change_column_null :saved_locations, :latitude, true
       change_column_null :saved_locations, :longitude, true
       remove_index :saved_locations, :name
       add_index :saved_locations, "LOWER(name)", unique: true,
         where: "is_saved = true", name: "index_saved_locations_on_reusable_name"
       add_reference :events, :saved_location, foreign_key: true

       # Match all three values; identical labels can refer to different pins.
       execute <<~SQL
      INSERT INTO saved_locations (name, latitude, longitude, is_saved, created_at, updated_at)
      SELECT DISTINCT COALESCE(e.location, ''), e.latitude, e.longitude, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM events e
      WHERE NOT EXISTS (
        SELECT 1 FROM saved_locations s
        WHERE s.name = COALESCE(e.location, '')
          AND s.latitude IS NOT DISTINCT FROM e.latitude
          AND s.longitude IS NOT DISTINCT FROM e.longitude
      )
    SQL
       execute <<~SQL
      UPDATE events e SET saved_location_id = (
        SELECT s.id FROM saved_locations s
        WHERE s.name = COALESCE(e.location, '')
          AND s.latitude IS NOT DISTINCT FROM e.latitude
          AND s.longitude IS NOT DISTINCT FROM e.longitude
        ORDER BY s.is_saved DESC, s.id LIMIT 1
      )
    SQL
       change_column_null :events, :saved_location_id, false
       remove_column :events, :location, :string
       remove_column :events, :latitude, :decimal, precision: 10, scale: 6
       remove_column :events, :longitude, :decimal, precision: 10, scale: 6
     end

  def down
       raise ActiveRecord::IrreversibleMigration,
         "Restore a database backup and the previous release together to undo location normalization."
  end
end
