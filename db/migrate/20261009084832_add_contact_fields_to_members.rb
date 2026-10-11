class AddContactFieldsToMembers < ActiveRecord::Migration[8.1]
     def change
          add_column :members, :phone_number, :string unless column_exists?(:members, :phone_number)
       add_column :members, :phone_visible, :boolean, default: false, null: false
     end
end
