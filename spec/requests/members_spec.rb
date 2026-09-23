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
    end
  end

  describe "PATCH /members/:id" do
    before { sign_in admin }

    it "updates the member's paid_dues status and redirects to the index" do
      target = create(:member, :profile_completed, paid_dues: false)

      patch member_path(target), params: { member: { paid_dues: true } }

      expect(response).to redirect_to(members_path)
      expect(target.reload.paid_dues).to be true
    end

    # This test is no longer true now that the admin can edit points 
    # it "ignores attributes other than paid_dues" do
    #   target = create(:member, :profile_completed, points: 5)

    #   patch member_path(target), params: { member: { paid_dues: true, points: 999 } }

    #   expect(target.reload.points).to eq(5)
    end
  end
end
