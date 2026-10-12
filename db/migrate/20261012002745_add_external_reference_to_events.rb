class AddExternalReferenceToEvents < ActiveRecord::Migration[8.1]
     def change
          add_column :events, :external_reference, :string
       add_index :events, :external_reference, unique: true
     end
end
