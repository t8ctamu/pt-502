require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:officer) do
    role = Role.find_or_create_by!(description: "admin")
    Member.create!(email: "officer@tamu.edu", uid: "o1",
                   first_name: "Off", last_name: "Icer", role: role,
                   profile_completed_at: Time.current)
  end

  before { sign_in officer }

  it "creates an event when all fields are valid" do
    expect {
      post events_path, params: { event: {
        name: "Meeting", description: "Details",
        starts_at: "2026-10-01 10:00", location: "Room 1"
      } }
    }.to change(Event, :count).by(1)

    expect(response).to redirect_to(events_path)
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