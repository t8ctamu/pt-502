require "rails_helper"

RSpec.describe "Members", type: :request do
  let(:admin) { create(:member, :admin, :profile_completed) }
  let(:regular_member) { create(:member, :profile_completed) }

  describe "GET /members" do
    context "when signed out" do
      it "redirects to sign in" do
        get members_path
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context "when signed in as a non-admin member" do
      before { sign_in regular_member }

      it "redirects to root with an alert" do
        get members_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when the signed-in admin's own profile is incomplete" do
      before { sign_in create(:member, :admin) }

      it "redirects to the profile edit form first" do
        get members_path
        expect(response).to redirect_to(edit_profile_path)
      end
    end

    context "when signed in as an admin with a completed profile" do
      before { sign_in admin }

      it "returns a successful response and lists members" do
        create(:member, :profile_completed, first_name: "Alex")

        get members_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Alex")
      end

      it "shows graduation, summer cycle, carpool availability, and opted-in phone numbers" do
        create(:member, :profile_completed, first_name: "Carpooler", car_pool_status: true,
               expected_graduation_term: "Fall 2028", pt_school_application_date: Date.new(2027, 6, 1),
               share_phone_number: true, phone_number: "979-555-0134")
        hidden = create(:member, :profile_completed)
        hidden.update_columns(phone_number: "979-555-0199", share_phone_number: false)
        get members_path
        expect(response.body).to include("Carpooler", "Fall 2028", "Summer 2027", "979-555-0134", "Not shared")
        expect(response.body).not_to include("979-555-0199")
      end
    end
  end

  describe "GET /members/:id/edit" do
    it "requires sign in" do
      get edit_member_path(regular_member)
      expect(response).to redirect_to(new_member_session_path)
    end

    it "does not allow regular members to edit another member" do
      sign_in regular_member
      get edit_member_path(admin)
      expect(response).to redirect_to(root_path)
    end

    it "allows officers to edit details without phone consent controls" do
      sign_in admin
      get edit_member_path(regular_member)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Expected graduation", "Anticipated application cycle")
      expect(response.body).not_to include('name="member[share_phone_number]"', 'name="member[phone_number]"')
    end
  end

  describe "PATCH /members/:id" do
    before { sign_in admin }

    it "does not change points through the dues update endpoint" do
      target = create(:member, :profile_completed, points: 5)
      patch member_path(target), params: { member: { paid_dues: true, points: 999 } }
      expect(target.reload.points).to eq(5)
    end

    it "updates the member's paid_dues status and redirects to the index" do
      target = create(:member, :profile_completed, paid_dues: false)

      patch member_path(target), params: { member: { paid_dues: true } }

      expect(response).to redirect_to(members_path)
      expect(target.reload.paid_dues).to be true
    end

    it "allows officers to update profile details but never phone consent, points, or roles" do
      target = create(:member, :profile_completed, share_phone_number: true, phone_number: "979-555-0123")
      original_role = target.role_id
      patch member_path(target), params: { member: {
        expected_graduation_term: "Fall 2029", pt_school_application_date: "2028-06-01", car_pool_status: "1",
        phone_number: "979-555-0199", share_phone_number: "0", points: 999, role_id: admin.role_id
      } }
      expect(response).to redirect_to(members_path)
      target.reload
      expect(target.expected_graduation_term).to eq("Fall 2029")
      expect(target.anticipated_application_cycle).to eq("Summer 2028")
      expect(target.car_pool_status?).to be true
      expect(target.shared_phone_number).to eq("979-555-0123")
      expect(target.role_id).to eq(original_role)
      expect(target.points).to eq(0)
    end

    it "does not allow an officer to opt a member into phone sharing" do
      target = create(:member, :profile_completed)
      patch member_path(target), params: { member: { expected_graduation_term: "Fall 2029", share_phone_number: "1", phone_number: "979-555-0123" } }
      expect(target.reload.share_phone_number?).to be false
      expect(target.phone_number).to be_nil
    end

    it "preserves existing details and explains an invalid officer edit" do
      target = create(:member, :profile_completed)
      original = target.attributes
      patch member_path(target), params: { member: { expected_graduation_term: "", pt_school_application_date: "2028-01-01" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Please correct your profile", "Please choose a summer term")
      expect(target.reload.attributes).to eq(original)
    end

    it "blocks unauthorized profile updates" do
      sign_out admin
      sign_in regular_member
      patch member_path(admin), params: { member: { expected_graduation_term: "Fall 2030" } }
      expect(response).to redirect_to(root_path)
      expect(admin.reload.expected_graduation_term).not_to eq("Fall 2030")
    end
  end
end
