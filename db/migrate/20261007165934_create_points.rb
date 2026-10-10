class CreatePoints < ActiveRecord::Migration[8.1]
     def change
          create_table :points do |t|
               t.references :member, null: false, foreign_key: true
            t.references :requirement, null: false, foreign_key: true
            t.date    :awarded_date, null: false
            t.integer :point_amount, null: false
            t.string  :note
            t.timestamps
          end
     end
end
