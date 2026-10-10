require "rails_helper"

RSpec.describe "Submission reviews", type: :request do
     let(:member) { create(:member, :profile_completed) }
  let(:admin) { create(:member, :admin, :profile_completed) }
  let(:requirement) { create(:requirement, name: "Community Events", minimum_points: 1) }
  let!(:submission) { create(:event_submission, member: member, requirement: requirement) }

  context "as a regular member" do
       before { sign_in member }

    it "cannot see the queue" do
         get submission_reviews_path
      expect(response).to redirect_to(root_path)
    end

    it "cannot approve or deny" do
         patch approve_submission_review_path(submission), params: { points: 5 }
      patch deny_submission_review_path(submission), params: { reason: "nope" }

      expect(submission.reload).to be_pending
      expect(member.reload.total_points).to eq(0)
    end
  end

  context "as an admin" do
       before { sign_in admin }

    it "lists pending requests with their details" do
         get submission_reviews_path
      expect(response.body).to include(submission.name, requirement.name)
    end

    it "approves, adds points to the right type and updates active status" do
         patch approve_submission_review_path(submission), params: { points: 1 }

      expect(response).to redirect_to(submission_reviews_path)
      expect(submission.reload).to be_approved
      expect(member.reload.points_by_requirement[requirement.id]).to eq(1)
      expect(member).to be_active_status
    end

    it "rejects a non-positive or non-numeric points value" do
         patch approve_submission_review_path(submission), params: { points: "abc" }
      expect(submission.reload).to be_pending
      expect(flash[:alert]).to include("whole number")
    end

    it "keeps the request pending and adds no points when approval fails" do
         allow_any_instance_of(EventSubmission).to receive(:approve!).and_raise(StandardError, "boom")

      patch approve_submission_review_path(submission), params: { points: 1 }

      expect(flash[:alert]).to include("still pending")
      expect(submission.reload).to be_pending
      expect(member.reload.total_points).to eq(0)
    end

    it "denies with a reason that the member can see" do
         patch deny_submission_review_path(submission), params: { reason: "No proof attached" }

      expect(submission.reload).to be_denied
      expect(member.reload.total_points).to eq(0)

      sign_in member
      get root_path
      expect(response.body).to include("Denied", "No proof attached")
    end

    it "requires a reason to deny" do
         patch deny_submission_review_path(submission), params: { reason: " " }
      expect(submission.reload).to be_pending
    end
  end
end
