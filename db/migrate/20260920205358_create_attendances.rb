class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      t.references :member, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.datetime :checked_in_at
      t.integer :attendance_status

      t.timestamps
    end
  end
end
