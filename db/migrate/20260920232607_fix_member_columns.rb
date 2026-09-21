class FixMemberColumns < ActiveRecord::Migration[8.1]
  def change
    rename_column :members, :FirstName,     :first_name
    rename_column :members, :LastName,      :last_name
    rename_column :members, :JoinAt,        :joined_at
    rename_column :members, :carPoolStatus, :car_pool_status

    # Your table has no role_id column, and from_google needs one
    add_reference :members, :role, null: false, foreign_key: true

    change_column_default :members, :points,          from: nil, to: 0
    change_column_default :members, :car_pool_status, from: nil, to: false
  end
end
