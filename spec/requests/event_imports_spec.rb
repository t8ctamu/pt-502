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
         allow_any_instance_of(Geocoding::Nominatim).to receive(:search).and_return([])
       end

    it "imports valid events from a CSV regardless of GetInvolved status" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/events.csv"), "text/csv"
         )
      post event_imports_path, params: { file: file }
      token = response.location.match(%r{/event_imports/([0-9a-f-]+)/preview})[1]

      # Sample file: one Approved, one Initiated, and two Submitted events.
      post confirm_event_import_path(token), params: {
        selected_rows: %w[2 3 4 5],
        assignments: {
          "2" => { requirement_id: "", point_value: "1" },
          "3" => { requirement_id: "", point_value: "1" },
          "4" => { requirement_id: "", point_value: "1" },
          "5" => { requirement_id: "", point_value: "1" }
        }
      }

      expect(Event.find_by(external_reference: "EVN-26955")).to be_present
      expect(Event.find_by(external_reference: "EVN-26994")).to be_present
      expect(Event.find_by(external_reference: "EVN-27798")).to be_present
      expect(Event.find_by(external_reference: "EVN-27792")).to be_present
      expect(flash[:notice]).to include("4 events added")
    end

    it "previews all statuses without saving any events" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/events.csv"), "text/csv"
         )
      post event_imports_path, params: { file: file }

      expect { follow_redirect! }.not_to change(Event, :count)

      page = Nokogiri::HTML(response.body)
      expect(page.css("th").map(&:text)).to include("Import action", "GetInvolved status")
      expect(page.css("tbody tr").map { |row| row.css("td")[3].text }).to match_array(
        %w[Initiated Submitted Approved Submitted]
      )
      expect(page.css('input[name="selected_rows[]"][checked]').size).to eq(4)
      expect(response.body).not_to include("not approved", "Approve them in GetInvolved")
    end

    it "imports only the selected events and counts the others as skipped" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/events.csv"), "text/csv"
         )
      post event_imports_path, params: { file: file }
      token = response.location.match(%r{/event_imports/([0-9a-f-]+)/preview})[1]

      expect {
           post confirm_event_import_path(token), params: { selected_rows: %w[2 3] }
      }.to change(Event, :count).by(2)

      expect(Event.pluck(:external_reference)).to match_array(%w[EVN-26994 EVN-27798])
      expect(flash[:notice]).to include("2 events added", "2 skipped")
    end

    it "saves nothing if no events are selected" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/events.csv"), "text/csv"
         )
      post event_imports_path, params: { file: file }
      token = response.location.match(%r{/event_imports/([0-9a-f-]+)/preview})[1]

      expect { post confirm_event_import_path(token) }.not_to change(Event, :count)
      expect(flash[:notice]).to include("0 events added", "4 skipped")
    end
  end
end
