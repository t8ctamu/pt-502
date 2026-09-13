class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :FirstName
      t.string :LastName
      t.string :email
      t.date :JoinAt
      t.boolean :carPoolStatus
      t.integer :points

      t.timestamps
    end
  end
end
