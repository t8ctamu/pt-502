class BackfillAndRequireSemesterOnPoints < ActiveRecord::Migration[8.1]
     class MigrationSemester < ApplicationRecord
          self.table_name = "semesters"
     end

  class MigrationPoint < ApplicationRecord
       self.table_name = "points"
  end

  def up
       semester = MigrationSemester.find_or_create_by!(name: "Fall 2026") do |s|
            s.starts_on = Date.new(2026, 8, 1)
         s.ends_on   = Date.new(2026, 12, 31)
       end

    MigrationPoint.where(semester_id: nil).update_all(semester_id: semester.id)

    change_column_null :points, :semester_id, false
  end

  def down
       change_column_null :points, :semester_id, true
  end
end
