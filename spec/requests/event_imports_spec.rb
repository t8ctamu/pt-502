require "rails_helper"

RSpec.describe "EventImports", type: :request do
     let(:admin) { create(:member, :admin, :profile_completed) }
  let(:regular) { create(:member, :profile_completed) }

  describe "GET /event_imports/new" do
       it "redirects signed-out users" do
            get new_event_import_path
         expect(response).to redirect_to(new_member_session_path)
       end

    it "redirects regular members" do
         sign_in regular
      get new_event_import_path
      expect(response).to redirect_to(root_path)
    end

    it "renders for admins" do
         sign_in admin
      get new_event_import_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Import Events from GetInvolved")
    end
  end

  describe "POST /event_imports" do
       before { sign_in admin }

    it "rejects non-csv/xlsx uploads" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/bad.txt"), "text/plain"
         )
      post event_imports_path, params: { file: file }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please upload")
    end

    it "accepts a csv and redirects to preview" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/events.csv"), "text/csv"
         )
      post event_imports_path, params: { file: file }
      expect(response).to redirect_to(%r{/event_imports/[0-9a-f-]+/preview})
    end
  end

  describe "end-to-end import" do
       before do
            sign_in admin
         create(:requirement, name: "Service")
       end

    it "imports approved events from a CSV and skips the rest" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/events.csv"), "text/csv"
         )
      post event_imports_path, params: { file: file }
      token = response.location.match(%r{/event_imports/([0-9a-f-]+)/preview})[1]

      # Sample file: 1 approved (EVN-26955), 3 not approved. Only 1 should import.
      post confirm_event_import_path(token), params: {
        assignments: {
          "2" => { requirement_id: "", point_value: "1" },
          "3" => { requirement_id: "", point_value: "1" },
          "4" => { requirement_id: "", point_value: "1" },
          "5" => { requirement_id: "", point_value: "1" }
        }
      }

      expect(Event.find_by(external_reference: "EVN-26955")).to be_present
      expect(Event.find_by(external_reference: "EVN-26994")).to be_nil
      expect(Event.find_by(external_reference: "EVN-27798")).to be_nil
    end
  end
end
