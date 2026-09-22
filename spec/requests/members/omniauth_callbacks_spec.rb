require "rails_helper"

RSpec.describe "Members::OmniauthCallbacks", type: :request do
  before { OmniAuth.config.test_mode = true }

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  def mock_google_auth(email:, uid: "google-uid-123", first_name: "Ada", last_name: "Lovelace")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: {
        email: email,
        first_name: first_name,
        last_name: last_name,
        image: "https://example.com/avatar.png"
      }
    )
  end

  describe "GET /members/auth/google_oauth2/callback" do
    context "with a tamu.edu email" do
      it "signs in an existing member and redirects to root" do
        member = create(:member, :profile_completed, email: "ada#{Member::ALLOWED_EMAIL_DOMAIN}")
        mock_google_auth(email: member.email)

        get member_google_oauth2_omniauth_callback_path

        expect(response).to redirect_to(root_path)
      end

      it "creates a new member on first sign-in and sends them to finish their profile" do
        mock_google_auth(email: "brandnew#{Member::ALLOWED_EMAIL_DOMAIN}")

        expect {
          get member_google_oauth2_omniauth_callback_path
        }.to change(Member, :count).by(1)

        expect(response).to redirect_to(edit_profile_path)

        new_member = Member.find_by(email: "brandnew#{Member::ALLOWED_EMAIL_DOMAIN}")
        expect(new_member.role.description).to eq("Member")
      end
    end

    context "with a non-tamu.edu email" do
      it "does not sign the member in and redirects to sign in with an alert" do
        mock_google_auth(email: "someone@gmail.com")

        expect {
          get member_google_oauth2_omniauth_callback_path
        }.not_to change(Member, :count)

        expect(response).to redirect_to(new_member_session_path)
        expect(flash[:alert]).to match(/Texas A&M account/)
      end
    end
  end
end
