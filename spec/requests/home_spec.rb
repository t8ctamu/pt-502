require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /index" do
    it "redirects to sign in when signed out" do
      get "/home/index"
      expect(response).to redirect_to(new_member_session_path)
    end

    it "returns http success for a member with a completed profile" do
      sign_in create(:member, :profile_completed)

      get "/home/index"
      expect(response).to have_http_status(:success)
    end

    it "redirects to the profile form when the profile is incomplete" do
      sign_in create(:member)

      get "/home/index"
      expect(response).to redirect_to(edit_profile_path)
    end
  end
end
