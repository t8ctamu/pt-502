class CreateSemesters < ActiveRecord::Migration[8.1]
     def change
          create_table :semesters do |t|
               t.string :name, null: false
            t.date :starts_on, null: false
            t.date :ends_on, null: false

            t.timestamps
          end

       add_index :semesters, :name, unique: true
       add_check_constraint :semesters, "ends_on >= starts_on", name: "semesters_valid_date_range"
     end
end
