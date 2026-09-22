require "rails_helper"

RSpec.describe "Members::Sessions", type: :request do
  describe "GET /members/sign_out" do
    it "signs the member out and redirects to the sign in page" do
      sign_in create(:member, :profile_completed)

      get destroy_member_session_path

      expect(response).to redirect_to(new_member_session_path)
    end
  end
end
