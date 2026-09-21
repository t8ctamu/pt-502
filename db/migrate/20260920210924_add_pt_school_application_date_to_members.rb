class AddPtSchoolApplicationDateToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :pt_school_application_date, :date
  end
end
