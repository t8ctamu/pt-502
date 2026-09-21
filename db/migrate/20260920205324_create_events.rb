class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name
      t.string :location
      t.datetime :starts_at
      t.datetime :ends_at
      t.text :description

      t.timestamps
    end
  end
end
