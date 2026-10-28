require "rails_helper"

RSpec.describe "EventImports", type: :request do
     let(:admin) { create(:member, :admin, :profile_completed) }
  let(:regular) { create(:member, :profile_completed) }

  def upload_events(filename = "events.csv")
       file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files", filename))
    upload_event_file(file)
  end

  def upload_event_file(file)
       @import_tokens ||= []
    post event_imports_path, params: { file: file }
    token = response.location.match(%r{/event_imports/([0-9a-f-]+)/preview})[1]
    @import_tokens << token
    token
  end

  after do
       Array(@import_tokens).each do |token|
            Dir.glob(Rails.root.join("tmp/event_imports", "#{token}.*")).each { |path| File.delete(path) }
       end
  end

  [ :regular, nil ].each do |member|
       context "when #{member || 'signed out'} tries to import" do
            it "rejects upload, preview, and confirmation without saving events" do
                 sign_in public_send(member) if member
              token = SecureRandom.uuid
              destination = member ? root_path : new_member_session_path

              expect {
                   post event_imports_path
                expect(response).to redirect_to(destination)
                get preview_event_import_path(token)
                expect(response).to redirect_to(destination)
                post confirm_event_import_path(token), params: { selected_rows: [ "2" ] }
                expect(response).to redirect_to(destination)
              }.not_to change(Event, :count)
            end
       end
  end

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
         upload_events
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
         token = upload_events

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
         upload_events

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
         token = upload_events

      expect {
           post confirm_event_import_path(token), params: { selected_rows: %w[2 3] }
      }.to change(Event, :count).by(2)

      expect(Event.pluck(:external_reference)).to match_array(%w[EVN-26994 EVN-27798])
      expect(flash[:notice]).to include("2 events added", "2 skipped")
    end

    it "saves nothing if no events are selected" do
         token = upload_events

      expect { post confirm_event_import_path(token) }.not_to change(Event, :count)
      expect(flash[:notice]).to include("0 events added", "4 skipped")
    end

    [ "events.csv", "events.xlsx" ].each do |filename|
         it "imports and re-imports every status from #{filename} without duplicates" do
              token = upload_events(filename)
           expect { get preview_event_import_path(token) }.not_to change(Event, :count)
           expect(response).to have_http_status(:ok)

           expect {
                post confirm_event_import_path(token), params: { selected_rows: %w[2 3 4 5] }
           }.to change(Event, :count).by(4)
           expect(flash[:notice]).to include("4 events added")

           original_ids = Event.order(:external_reference).pluck(:id)
           Event.find_by!(external_reference: "EVN-26994").update!(name: "Old imported title")
           Event.find_by!(external_reference: "EVN-27798").update!(name: "Another old title")

           token = upload_events(filename)
           get preview_event_import_path(token)
           expect(Nokogiri::HTML(response.body).css("tr.row--update").size).to eq(4)

           expect {
                post confirm_event_import_path(token), params: { selected_rows: %w[2 3 4 5] }
           }.not_to change(Event, :count)

           expect(Event.order(:external_reference).pluck(:id)).to eq(original_ids)
           expect(Event.find_by!(external_reference: "EVN-26994").name).to start_with("1st General Meeting")
           expect(Event.find_by!(external_reference: "EVN-27798").name).to include("Classic Skills Workshop")
           expect(flash[:notice]).to include("0 events added", "4 updated")
         end
    end

    it "shows row-specific issues and holds invalid rows back even if submitted as selected" do
         token = upload_events("events_with_issues.csv")
      get preview_event_import_path(token)
      page = Nokogiri::HTML(response.body)

      expect(page.css("tr.row--error").size).to eq(4)
      expect(page.css('input[name="selected_rows[]"]').map { |input| input["value"] }).to eq([ "2" ])
      { "3" => "Missing location", "4" => "Could not parse starts", "5" => "Missing reference", "6" => "Missing title" }.each do |row, message|
           issue_row = page.css("tbody tr").find { |tr| tr.css("td")[1].text.strip == row }
        expect(issue_row.text).to include(message)
      end

      expect {
           post confirm_event_import_path(token), params: { selected_rows: %w[2 3 4 5 6] }
      }.to change(Event, :count).by(1)

      expect(Event.pluck(:external_reference)).to eq([ "EVN-VALID" ])
      expect(flash[:notice]).to include("1 event added", "4 had issues")
    end

    it "identifies missing required columns instead of treating status as an error" do
         file = Tempfile.new([ "missing_columns", ".csv" ])
      file.write("Title,Status\nTraining event,Initiated\n")
      file.rewind
      upload_event_file(Rack::Test::UploadedFile.new(file.path, "text/csv"))
      follow_redirect!

      expect(response.body).to include("Missing reference", "Missing start time", "Missing location")
      expect(response.body).not_to include("not Approved")
      expect(Nokogiri::HTML(response.body).css('input[name="selected_rows[]"]')).to be_empty
    ensure
         file.close!
    end

    it "reports an unreadable Excel file without saving events" do
         file = Tempfile.new([ "corrupt_events", ".xlsx" ])
      file.write("This is not an Excel workbook")
      file.rewind
      upload_event_file(Rack::Test::UploadedFile.new(file.path))

      expect { follow_redirect! }.not_to change(Event, :count)
      expect(response).to redirect_to(new_event_import_path)
      expect(flash[:alert]).to include("could not be read")
    ensure
         file.close!
    end

    it "lets a manager import events too" do
         sign_out admin
      sign_in create(:member, :manager, :profile_completed)
      token = upload_events

      expect {
           post confirm_event_import_path(token), params: { selected_rows: [ "2" ] }
      }.to change(Event, :count).by(1)
    end
  end
end
