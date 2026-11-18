class AddTshirtSizeToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :tshirt_size, :string
  end
end
