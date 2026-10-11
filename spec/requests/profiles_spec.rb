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
          expected_graduation_term: "Spring 2027",
          pt_school_application_date: "2027-06-01",
          car_pool_status: "1"
        }
      }
    end

    it "saves a valid profile, marks it complete, and redirects to root" do
      patch profile_path, params: valid_params

      expect(response).to redirect_to(root_path)
      member.reload
      expect(member.first_name).to eq("Taylor")
      expect(member.expected_graduation_term).to eq("Spring 2027")
      expect(member.anticipated_application_cycle).to eq("Summer 2027")
      expect(member.car_pool_status?).to be true
      expect(member).to be_profile_completed
      follow_redirect!
      expect(response.body).to include("Profile saved.", "Spring 2027", "Summer 2027", "Not shared")
    end

    it "saves a shared phone number and shows it on the member's profile" do
      patch profile_path, params: valid_params.deep_merge(member: { share_phone_number: "1", phone_number: "979-555-0123" })
      expect(member.reload.shared_phone_number).to eq("979-555-0123")
      follow_redirect!
      expect(response.body).to include("979-555-0123")
    end

    it "discards a phone number supplied without consent" do
      patch profile_path, params: valid_params.deep_merge(member: { share_phone_number: "0", phone_number: "979-555-0123" })
      expect(member.reload.phone_number).to be_nil
      follow_redirect!
      expect(response.body).not_to include("979-555-0123")
    end

    it "keeps previously saved details when a shared phone number is invalid" do
      member.update!(expected_graduation_term: "Fall 2028", pt_school_application_date: Date.new(2028, 6, 1),
                     share_phone_number: true, phone_number: "979-555-0123", profile_completed_at: Time.current)
      original = member.attributes
      patch profile_path, params: valid_params.deep_merge(member: { share_phone_number: "1", phone_number: "123" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("valid phone number", 'href="#member_phone_number"', 'value="123"')
      expect(member.reload.attributes).to eq(original)
    end

    it "removes the number and disables carpool availability when unchecked" do
      member.update!(share_phone_number: true, phone_number: "979-555-0123", car_pool_status: true)
      patch profile_path, params: valid_params.deep_merge(member: { share_phone_number: "0", car_pool_status: "0" })
      expect(member.reload.phone_number).to be_nil
      expect(member.car_pool_status?).to be false
    end

    it "rejects a forged non-summer date without completing the profile" do
      patch profile_path, params: valid_params.deep_merge(member: { pt_school_application_date: "2027-01-01" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Please choose a summer term")
      expect(member.reload).not_to be_profile_completed
    end

    it "rejects missing graduation, blank names, and invalid dates without saving" do
      [ { expected_graduation_term: "" }, { first_name: "" }, { last_name: "" },
        { pt_school_application_date: "not-a-date" } ].each do |attributes|
        patch profile_path, params: valid_params.deep_merge(member: attributes)
        expect(response).to have_http_status(:unprocessable_content)
        expect(member.reload).not_to be_profile_completed
      end
    end

    it "always edits the signed-in member even if another member id is submitted" do
      other = create(:member, first_name: "Other")
      patch profile_path, params: valid_params.deep_merge(member: { id: other.id }, id: other.id)
      expect(other.reload.first_name).to eq("Other")
      expect(member.reload.first_name).to eq("Taylor")
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
      expect(member.points).not_to eq(500)
    end
  end
end
