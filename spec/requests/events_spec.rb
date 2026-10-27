require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:admin) do
    role = Role.find_or_create_by!(description: "admin")
    Member.create!(email: "admin@tamu.edu", uid: "o1",
                   first_name: "Off", last_name: "Icer", role: role,
                   profile_completed_at: Time.current)
  end

  before { sign_in admin }

  it "creates an event when all fields are valid" do
    expect {
      post events_path, params: { event: {
        name: "Meeting", description: "Details",
        starts_at: "2026-10-01 10:00", location: "Room 1",
        latitude: "30.628", longitude: "-96.3344"
      } }
    }.to change(Event, :count).by(1)

    expect(response).to redirect_to(events_path)
  end

  it "creates a named event without a pin and requires coordinates before sharing check-in" do
    expect {
      post events_path, params: { event: {
        name: "Meeting", description: "Details",
        starts_at: "2026-10-01 10:00", location: "Room 1"
      } }
    }.to change(Event, :count).by(1)

    expect(response).to redirect_to(events_path)
    event = Event.order(:id).last
    expect(event).not_to be_check_in_configured

    get check_in_qr_event_path(event)
    expect(response).to redirect_to(edit_event_path(event))
  end

  it "does not create an event when a required field is blank" do
    expect {
      post events_path, params: { event: {
        name: "", description: "Details",
        starts_at: "2026-10-01 10:00", location: "Room 1"
      } }
    }.not_to change(Event, :count)

    expect(response).to have_http_status(422)
    expect(CGI.unescapeHTML(response.body)).to include("Name can't be blank")
  end
end

RSpec.describe "Event calendar", type: :request do
  let(:admin_role) { Role.find_or_create_by!(description: "admin") }
  let(:member) do
    Member.create!(email: "member@tamu.edu", uid: "m1",
                   first_name: "Mem", last_name: "Ber", role: admin_role,
                   profile_completed_at: Time.current)
  end
  let(:event) do
    Event.create!(name: "Meeting", description: "Details",
                  starts_at: Time.utc(2026, 10, 1, 10, 0),
                  ends_at:   Time.utc(2026, 10, 1, 11, 0),
                  location: "Room 1",
                  latitude: 30.628, longitude: -96.3344)
  end

  before { sign_in member }

  describe "Sunny: member views event and downloads calendar file" do
    it "shows the event details" do
      get event_path(event)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Meeting")
      expect(response.body).to include("Room 1")
      expect(response.body).to include("Details")
    end

    it "returns a valid .ics file with the event's data" do
      get ics_event_path(event, format: :ics)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/calendar")
      expect(response.body).to include("SUMMARY:Meeting")
      expect(response.body).to include("LOCATION:Room 1")
      expect(response.body).to include("DTSTART:20261001T100000Z")
    end
  end

  describe "Rainy: event was edited after the page loaded" do
    it "returns the latest details from the database" do
      get event_path(event)
      expect(response.body).to include("Room 1")

      event.update!(location: "Room 2", name: "Meeting (updated)")

      get event_path(event)
      expect(response.body).to include("Room 2")
      expect(response.body).to include("Meeting (updated)")
    end
  end

  describe "Rainy: calendar generation fails" do
    it "redirects back to the event with an alert and keeps details visible" do
      allow_any_instance_of(EventsController)
        .to receive(:send_data).and_raise(StandardError, "boom")

      get ics_event_path(event, format: :ics)

      expect(response).to redirect_to(event_path(event))
      follow_redirect!
      expect(CGI.unescapeHTML(response.body)).to include("Couldn't generate the calendar file")
      expect(response.body).to include("Meeting")
      expect(response.body).to include("Room 1")
    end
  end
end
