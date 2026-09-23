class AddUniqueIndexToRolesDescription < ActiveRecord::Migration[8.1]
  def change
    add_index :roles, :description, unique: true, name: "index_roles_on_description"
  end
end
