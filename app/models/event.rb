class Event < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :members, through: :attendances

  validates :name, :description, :starts_at, :location, presence: true
  validate :ends_at_after_starts_at

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    if ends_at <= starts_at
      errors.add(:ends_at, "must be after the start time")
    end
  end
end
