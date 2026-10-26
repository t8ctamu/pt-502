require "rails_helper"

RSpec.describe "Event attendance", type: :request do
  let(:event) { create(:event) }
  let(:officer) { create(:member, :admin, :profile_completed) }

  it "shows an officer only checked-in members for the selected event" do
    sign_in officer
    member = create(:member, first_name: "Alice", last_name: "Nguyen")
    checked_in_at = Time.utc(2026, 9, 22, 15, 30)
    create(:attendance, event: event, member: member, checked_in_at: checked_in_at)
    absent = create(:attendance, event: event)
    other = create(:attendance, checked_in_at: checked_in_at)

    get event_path(event)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
    "Alice Nguyen",
    checked_in_at.in_time_zone.iso8601,
    "Check-in time"
  )
    expect(response.body).not_to include(absent.member.last_name, other.member.last_name)
  end

  it "shows an empty state and includes new check-ins after refreshing" do
    sign_in officer
    get event_path(event)
    expect(response.body).to include("No attendees yet.")

    member = create(:member, first_name: "New", last_name: "Attendee")
    create(:attendance, event: event, member: member, checked_in_at: Time.current)
    get event_path(event)

    expect(response.body).to include("New Attendee")
    expect(response.body).not_to include("No attendees yet.")
  end

  it "keeps event details visible with a retry message when attendance cannot load" do
    sign_in officer
    allow(Event).to receive(:find).with(event.id.to_s).and_return(event)
    allow(event).to receive(:attendances).and_raise(ActiveRecord::StatementInvalid)

    get event_path(event)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(event.name, "Please try again.", "Try again")
    expect(response.body).not_to include("No attendees yet.")
  end

  it "does not expose attendance or query it for ordinary members" do
    sign_in create(:member, :profile_completed)
    allow(Event).to receive(:find).with(event.id.to_s).and_return(event)
    expect(event).not_to receive(:attendances)

    get event_path(event)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("attendance-heading", "Check-in time")
  end

  it "requires signed-out visitors to sign in" do
    get event_path(event)

    expect(response).to redirect_to(new_member_session_path)
  end
end
