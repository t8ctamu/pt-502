class EventSubmission < ApplicationRecord
     class AlreadyReviewed < StandardError; end

  belongs_to :member
  belongs_to :requirement
  belongs_to :reviewed_by, class_name: "Member", optional: true
  belongs_to :point, optional: true

  enum :status, { pending: "pending", approved: "approved", denied: "denied" }, default: "pending"

  before_validation { self.name = name&.strip }

  validates :name, presence: { message: "is required" }
  validates :description, presence: { message: "is required (describe the event or add proof)" }
  validates :event_date, presence: { message: "is required and must be a valid date" }
  validates :name, uniqueness: { scope: %i[member_id event_date], case_sensitive: false,
                                 message: "was already submitted by you for that date" }
  validates :denial_reason, presence: true, if: :denied?
  validate :event_date_not_in_future
  validate :requirement_is_active, on: :create

  def approve!(reviewer:, points:)
       with_lock do
            raise AlreadyReviewed unless pending?

         award = member.point_entries.create!(
           requirement: requirement, point_amount: points,
           awarded_date: Date.current, note: "Approved submission: #{name}"
         )
         update!(status: :approved, reviewed_by: reviewer, reviewed_at: Time.current, point: award)
       end
  end

  def deny!(reviewer:, reason:)
       with_lock do
            raise AlreadyReviewed unless pending?

         update!(status: :denied, reviewed_by: reviewer, reviewed_at: Time.current, denial_reason: reason)
       end
  end

  private

       def event_date_not_in_future
            errors.add(:event_date, "can't be in the future") if event_date.present? && event_date > Date.current
       end

  def requirement_is_active
       errors.add(:requirement, "is not available") if requirement && !requirement.is_active
  end
end
