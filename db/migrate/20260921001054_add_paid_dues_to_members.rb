class AddPaidDuesToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :paid_dues, :boolean, null: false, default: false
  end
end
