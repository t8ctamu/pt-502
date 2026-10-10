require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:member) { create(:member) }

  before { sign_in member }

  describe "GET /profile/edit" do
    it "returns a successful response" do
      get edit_profile_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /profile" do
    let(:valid_params) do
      {
        member: {
          first_name: "Taylor",
          last_name: "Reed",
          pt_school_application_date: 1.year.from_now.to_date.to_s,
          car_pool_status: "1"
        }
      }
    end

    it "saves a valid profile, marks it complete, and redirects to root" do
      patch profile_path, params: valid_params

      expect(response).to redirect_to(root_path)
      member.reload
      expect(member.first_name).to eq("Taylor")
      expect(member).to be_profile_completed
    end

    it "re-renders the form when pt_school_application_date is missing" do
      patch profile_path, params: { member: { first_name: "Taylor", last_name: "Reed", pt_school_application_date: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(member.reload.profile_completed?).to be false
    end

    it "does not allow a member to assign their own role or points" do
      admin_role = create(:role, :admin)
      original_role_id = member.role_id

      patch profile_path, params: valid_params.deep_merge(member: { role_id: admin_role.id, points: 500 })

      member.reload
      expect(member.role_id).to eq(original_role_id)
      expect(member.total_points).to eq(0)
      expect(Point.where(member: member)).to be_empty
    end
  end
end
