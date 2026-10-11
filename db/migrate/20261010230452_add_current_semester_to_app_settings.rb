class AddCurrentSemesterToAppSettings < ActiveRecord::Migration[8.1]
     def change
          add_reference :app_settings, :current_semester,
                        foreign_key: { to_table: :semesters },
                        null: true
     end
end
