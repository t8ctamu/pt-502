class RemoveLegacyPointColumns < ActiveRecord::Migration[8.1]
     def change
          remove_column :members, :points, :integer, default: 0
       remove_column :attendances, :points_awarded, :integer, default: 0, null: false
     end
end
