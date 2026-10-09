class CreateSavedLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :saved_locations do |t|
      t.string :name, null: false
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.timestamps
    end
    add_index :saved_locations, :name, unique: true
  end
end
