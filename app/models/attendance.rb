class Attendance < ApplicationRecord
  belongs_to :member
  belongs_to :event

  validates :member_id, uniqueness: { scope: :event_id, message: "has already checked in to this event" }
end
