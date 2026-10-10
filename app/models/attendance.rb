class Attendance < ApplicationRecord
  belongs_to :member
  belongs_to :event
  belongs_to :point, optional: true

  validates :member_id, uniqueness: { scope: :event_id, message: "has already checked in to this event" }

  def points_awarded
    point&.point_amount.to_i
  end
end