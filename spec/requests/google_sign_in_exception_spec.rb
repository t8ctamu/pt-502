require "rails_helper"

RSpec.describe "Google sign in allowlist", type: :request do
     let(:exception_email) { "tamupts1@gmail.com" }

  before do
       OmniAuth.config.test_mode = true
    OmniAuth.config.logger = Logger.new(nil)
  end

  after do
       OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  def mock_google(email)
       OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
         provider: "google_oauth2",
         uid: "123456789",
         info: { email: email, first_name: "Some", last_name: "One", name: "Some One" }
       )
  end

  # Devise's default route helper for the Google callback on a :member model.
  def google_callback
       get member_google_oauth2_omniauth_callback_path
  end

  # Signed in = the app no longer bounces us to the sign-in page.
  def signed_in?
       get root_path
    response.location != new_member_session_url
  end

  describe "Sunny: allowed emails" do
       it "lets the allowlisted exception email sign in" do
            mock_google(exception_email)

         expect { google_callback }.to change(Member, :count).by(1)
         expect(Member.last.email).to eq(exception_email)
         expect(signed_in?).to be(true)
       end

    it "lets the exception email sign in regardless of letter case" do
         mock_google(exception_email.upcase)

      google_callback
      expect(signed_in?).to be(true)
    end

    it "still lets a @tamu.edu email sign in" do
         mock_google("student@tamu.edu")

      google_callback
      expect(signed_in?).to be(true)
    end
  end

  describe "Rainy: emails that are not allowed" do
       it "rejects a different gmail address" do
            mock_google("stranger@gmail.com")

         expect { google_callback }.not_to change(Member, :count)
         expect(signed_in?).to be(false)
       end

    it "rejects an email that only looks like the exception" do
         mock_google("someone@gmail.com.evil.com")

      expect { google_callback }.not_to change(Member, :count)
      expect(signed_in?).to be(false)
    end
  end
end
