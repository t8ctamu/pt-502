class Point < ApplicationRecord
     belongs_to :member
  belongs_to :requirement
  belongs_to :semester
  has_one :attendance, dependent: :nullify

  validates :awarded_date, presence: true
  validates :point_amount, numericality: { only_integer: true }

  before_validation :assign_current_semester, on: :create

  private

       def assign_current_semester
            self.semester ||= AppSetting.current_semester
       end
end
