require "rails_helper"
require Rails.root.join("db/migrate/20261123000000_normalize_event_locations")

RSpec.describe NormalizeEventLocations do
     it "preserves pins and unpinned venues, sharing only exact matches" do
          connection = ActiveRecord::Base.connection
          original_path = connection.schema_search_path
          connection.execute("CREATE SCHEMA normalization_migration_test")
          connection.schema_search_path = "normalization_migration_test"
          connection.create_table(:saved_locations) do |t|
               t.string :name, null: false
            t.decimal :latitude, precision: 10, scale: 6, null: false
            t.decimal :longitude, precision: 10, scale: 6, null: false
            t.timestamps
          end
          connection.add_index :saved_locations, :name, unique: true
          connection.create_table(:events) do |t|
               t.string :name
            t.string :location
            t.decimal :latitude, precision: 10, scale: 6
            t.decimal :longitude, precision: 10, scale: 6
          end
          connection.execute <<~SQL
      INSERT INTO saved_locations (name, latitude, longitude, created_at, updated_at)
      VALUES ('Clinic', 30, -96, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
      INSERT INTO events (name, location, latitude, longitude) VALUES
      ('First', 'Clinic', 30, -96), ('Second', 'Clinic', 31, -97),
      ('Third', 'Online', NULL, NULL), ('Fourth', 'Clinic', 30, -96);
    SQL

          described_class.new.migrate(:up)
          rows = connection.select_all(<<~SQL).to_a
      SELECT e.name AS title, s.name, s.latitude, s.longitude, s.is_saved
      FROM events e JOIN saved_locations s ON s.id = e.saved_location_id ORDER BY e.id
    SQL
          expect(rows.map { |r| r["title"] }).to eq(%w[First Second Third Fourth])
          expect(rows.map { |r| r["latitude"]&.to_f }).to eq([ 30, 31, nil, 30 ])
          expect(rows.map { |r| r["longitude"]&.to_f }).to eq([ -96, -97, nil, -96 ])
          expect(rows.map { |r| r["is_saved"] }).to eq([ true, false, false, true ])
          expect(connection.select_value("SELECT COUNT(*) FROM saved_locations")).to eq(3)
          expect(connection.column_exists?(:events, :location)).to be false
        ensure
             if connection && original_path
                  connection.schema_search_path = original_path
               connection.execute("DROP SCHEMA IF EXISTS normalization_migration_test CASCADE")
             end
     end
end
