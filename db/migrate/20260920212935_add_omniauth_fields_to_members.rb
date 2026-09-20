class AddOmniauthFieldsToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :uid, :string
    add_column :members, :avatar_url, :string
    add_column :members, :profile_completed_at, :datetime
    add_index  :members, :uid, unique: true
  end
end