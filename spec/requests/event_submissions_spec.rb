require "rails_helper"

RSpec.describe "Event submissions", type: :request do
     let(:member) { create(:member, :profile_completed) }
  let(:admin) { create(:member, :admin, :profile_completed) }
  let(:requirement) { create(:requirement, name: "Community Events", minimum_points: 1) }

  describe "POST /event_submissions" do
       before { sign_in member }

    let(:valid_params) do
         { event_submission: { name: "Habitat build day", event_date: (Date.current - 1).to_s,
                               requirement_id: requirement.id, description: "Photo attached" } }
    end

    it "saves a pending submission and confirms it" do
         expect { post event_submissions_path, params: valid_params }
           .to change(EventSubmission, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(EventSubmission.last).to be_pending
      expect(member.reload.total_points).to eq(0)
    end

    it "shows a clear error and keeps what was typed when a field is missing" do
         params = valid_params
      params[:event_submission][:description] = ""

      expect { post event_submissions_path, params: params }.not_to change(EventSubmission, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Please fill in all required fields")
      expect(response.body).to include("Habitat build day")
    end

    it "rejects an invalid date" do
         params = valid_params
      params[:event_submission][:event_date] = "not-a-date"

      post event_submissions_path, params: params

      expect(response).to have_http_status(:unprocessable_content)
      expect(EventSubmission.count).to eq(0)
    end

    it "rejects a duplicate submission" do
         post event_submissions_path, params: valid_params
      expect { post event_submissions_path, params: valid_params }
        .not_to change(EventSubmission, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
