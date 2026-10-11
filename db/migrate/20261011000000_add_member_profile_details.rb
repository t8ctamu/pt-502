class AddMemberProfileDetails < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :expected_graduation_term, :string
    add_column :members, :phone_number, :string
    add_column :members, :share_phone_number, :boolean, default: false, null: false
  end
end
