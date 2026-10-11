class AddSemesterToPoints < ActiveRecord::Migration[8.1]
     def change
          add_reference :points, :semester, foreign_key: true, null: true
     end
end
