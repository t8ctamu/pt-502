class AddUniqueMemberEventIndexToAttendances < ActiveRecord::Migration[8.1]
  def change
    add_index :attendances, [ :member_id, :event_id ], unique: true
  end
end
