class ConsolidateMemberPhoneConsent < ActiveRecord::Migration[8.1]
     def up
          execute "UPDATE members SET phone_visible = phone_visible OR share_phone_number"
       remove_column :members, :share_phone_number
     end

  def down
       add_column :members, :share_phone_number, :boolean, default: false, null: false
    execute "UPDATE members SET share_phone_number = phone_visible"
  end
end
