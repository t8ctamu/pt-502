class AppSetting < ApplicationRecord
     belongs_to :current_semester, class_name: "Semester", optional: true

  validates :total_points_required,
            numericality: { only_integer: true, greater_than_or_equal_to: 0,
                            message: "must be a whole number, 0 or more" }

  def self.current
       first_or_create!
  end

  def self.total_points_required
       current.total_points_required
  end

  def self.current_semester
       current.current_semester
  end
end
