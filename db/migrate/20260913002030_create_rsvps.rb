class CreateRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :rsvps do |t|
      t.references :member, null: false, foreign_key: true
      t.boolean :response
      t.date :respondedAt

      t.timestamps
    end
  end
end
