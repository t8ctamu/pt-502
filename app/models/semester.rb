class Semester < ApplicationRecord
     has_many :points, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :starts_on, presence: true
  validates :ends_on, presence: true
  validate :ends_on_after_starts_on

  private

       def ends_on_after_starts_on
            return if starts_on.blank? || ends_on.blank?

         if ends_on < starts_on
              errors.add(:ends_on, "must be on or after the start date")
         end
       end
end
