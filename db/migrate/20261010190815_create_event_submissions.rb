class CreateEventSubmissions < ActiveRecord::Migration[8.1]
     def change
          create_table :event_submissions do |t|
               t.references :member, null: false, foreign_key: true
            t.references :requirement, null: false, foreign_key: true
            t.string :name, null: false
            t.date :event_date, null: false
            t.text :description, null: false
            t.string :status, null: false, default: "pending"
            t.references :reviewed_by, foreign_key: { to_table: :members, on_delete: :nullify }
            t.datetime :reviewed_at
            t.text :denial_reason
            t.references :point, foreign_key: { on_delete: :nullify }
            t.timestamps
          end

       add_index :event_submissions, :status
       add_index :event_submissions, "member_id, lower(name), event_date",
                 unique: true, name: "index_event_submissions_on_member_name_date"
       add_check_constraint :event_submissions,
         "status IN ('pending', 'approved', 'denied')", name: "event_submissions_status_valid"
     end
end
