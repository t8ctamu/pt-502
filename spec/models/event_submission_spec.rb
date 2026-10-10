require "rails_helper"

RSpec.describe EventSubmission, type: :model do
     let(:reviewer) { create(:member, :admin, :profile_completed) }

  it "is valid from the factory and starts pending" do
       submission = build(:event_submission)
    expect(submission).to be_valid
    expect(submission).to be_pending
  end

  it "requires a name, a date and a description" do
       submission = build(:event_submission, name: "", event_date: nil, description: "")
    expect(submission).not_to be_valid
    expect(submission.errors.attribute_names).to include(:name, :event_date, :description)
  end

  it "rejects a future date" do
       expect(build(:event_submission, event_date: Date.current + 1)).not_to be_valid
  end

  it "rejects a duplicate for the same member, name (any case) and date" do
       first = create(:event_submission, name: "Habitat build day")
    dup = build(:event_submission, member: first.member, requirement: first.requirement,
                                   name: "habitat BUILD day", event_date: first.event_date)
    expect(dup).not_to be_valid
  end

  it "allows the same name on a different date" do
       first = create(:event_submission)
    other = build(:event_submission, member: first.member, requirement: first.requirement,
                                     name: first.name, event_date: first.event_date - 1)
    expect(other).to be_valid
  end

  describe "#approve!" do
       it "adds a point of the right type, links it, and marks the request approved" do
            submission = create(:event_submission)

         submission.approve!(reviewer: reviewer, points: 2)

         expect(submission.reload).to be_approved
         expect(submission.reviewed_by).to eq(reviewer)
         expect(submission.point.point_amount).to eq(2)
         expect(submission.point.requirement).to eq(submission.requirement)
         expect(submission.member.total_points).to eq(2)
       end

    it "cannot be approved twice or award twice" do
         submission = create(:event_submission)
      submission.approve!(reviewer: reviewer, points: 1)

      expect { submission.approve!(reviewer: reviewer, points: 1) }
        .to raise_error(EventSubmission::AlreadyReviewed)
      expect(submission.member.total_points).to eq(1)
    end

    it "stays pending and adds no points when saving fails" do
         submission = create(:event_submission)
      allow(submission).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

      expect { submission.approve!(reviewer: reviewer, points: 1) }
        .to raise_error(ActiveRecord::RecordInvalid)

      expect(submission.reload).to be_pending
      expect(Point.where(member: submission.member).count).to eq(0)
    end
  end

  describe "#deny!" do
       it "records the reason and adds no points" do
            submission = create(:event_submission)

         submission.deny!(reviewer: reviewer, reason: "No proof attached")

         expect(submission.reload).to be_denied
         expect(submission.denial_reason).to eq("No proof attached")
         expect(submission.member.total_points).to eq(0)
       end

    it "requires a reason and stays pending without one" do
         submission = create(:event_submission)
      expect { submission.deny!(reviewer: reviewer, reason: "") }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect(submission.reload).to be_pending
    end
  end
end
