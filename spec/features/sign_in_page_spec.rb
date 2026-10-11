require "rails_helper"

RSpec.describe "Sign in page", type: :request do
     # Adjust if your sign-in page lives elsewhere (e.g. root_path).
     let(:sign_in_path) { new_member_session_path }

  describe "Sunny: a visitor sees only sign in / sign up" do
       before do
            create(:event, name: "Secret Mixer", location: "Hidden Hall")
         create(:member, :profile_completed, first_name: "Zelda", last_name: "Hiddenname")
       end

    it "shows no contact details, events, members, or points" do
         get sign_in_path

      expect(response).to have_http_status(:ok)
      body = CGI.unescapeHTML(response.body)

      expect(body).not_to include("ptsociety@example.com", "Contact", "Questions?")
      expect(body).not_to include("Secret Mixer", "Hidden Hall")
      expect(body).not_to include("Zelda", "Hiddenname")
      expect(body).not_to match(/points?/i)
      expect(body).not_to match(/dashboard/i)
    end

    it "offers Google sign in and sign up, plus the sign-in help link" do
         get sign_in_path
      body = CGI.unescapeHTML(response.body)

      expect(body).to include("Sign in with Google", "Sign up with Google")
      expect(body).to include("Help with signing in and using the app")
      expect(body).not_to include("ptsociety@example.com")
    end

    it "takes a signed-in user away from the sign-in page to the app" do
         sign_in create(:member, :profile_completed)

      get root_path

      expect(response).not_to redirect_to(new_member_session_path)
    end
  end

  describe "the help link on the sign-in page" do
       let!(:event)  { create(:event, name: "Secret Mixer") }
    let!(:member) { create(:member, :profile_completed, last_name: "Hiddenname") }

    it "opens for a visitor without exposing member or event details" do
         get member_help_path

      expect(response).to have_http_status(:ok)
      body = CGI.unescapeHTML(response.body)
      expect(body).not_to include("Secret Mixer", "Hiddenname")
    end
  end

  describe "Rainy: internal pages are closed to visitors" do
       let!(:event)  { create(:event) }
    let!(:member) { create(:member, :profile_completed) }

    it "redirects a visitor to sign in when opening the home page" do
         get root_path
      expect(response).to redirect_to(new_member_session_path)
    end

    it "redirects a visitor to sign in when opening the events list" do
         get events_path
      expect(response).to redirect_to(new_member_session_path)
    end

    it "redirects a visitor to sign in when opening an event" do
         get event_path(event)
      expect(response).to redirect_to(new_member_session_path)
      expect(response.body).not_to include(event.name)
    end

    it "redirects a visitor to sign in when opening the members list" do
         get members_path
      expect(response).to redirect_to(new_member_session_path)
    end

    {
      "the member edit page"     => -> { edit_member_path(member) },
      "the profile edit page"    => -> { edit_profile_path },
      "point settings"           => -> { point_settings_path },
      "semesters"                => -> { semesters_path },
      "submission reviews"       => -> { submission_reviews_path },
      "a new event submission"   => -> { new_event_submission_path },
      "the event check-in page"  => -> { event_check_in_path(event) },
      "the new event form"       => -> { new_event_path }
    }.each do |label, path|
         it "redirects a visitor to sign in when opening #{label}" do
              get instance_exec(&path)

           expect(response).to redirect_to(new_member_session_path)
           expect(response.body).not_to include(member.last_name, event.name)
         end
    end

    it "does not accept member changes from a visitor" do
         patch member_path(member), params: { member: { first_name: "Hacked" } }

      expect(response).to redirect_to(new_member_session_path)
      expect(member.reload.first_name).not_to eq("Hacked")
    end

    it "shows a clear message after the redirect, not a blank page" do
         get event_path(event)
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_present
      expect(CGI.unescapeHTML(response.body)).to include("Sign in with Google")
      expect(response.body).not_to include(event.name)
    end
  end
end
