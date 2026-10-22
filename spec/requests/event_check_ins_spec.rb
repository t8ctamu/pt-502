require "rails_helper"

RSpec.describe "Event check-in", type: :request do
  let!(:service) { create(:requirement, name: "Service", minimum_points: 3) }
  let(:event) do
    create(:event, :check_in_ready, latitude: 30.6, longitude: -96.3, point_value: 2, requirement: service)
  end
  let(:member) { create(:member, :profile_completed) }
  let(:officer) { create(:member, :admin, :profile_completed) }

  it "requires login and remembers the scanned event" do
    get event_check_in_path(event)
    expect(response).to redirect_to(new_member_session_path)
    expect(request.session["member_return_to"]).to eq(event_check_in_path(event))
    expect(Attendance.count).to eq(0)
  end

  it "shows a retry message when the attendance save fails" do
    sign_in member
    allow(EventCheckIn).to receive(:call).and_raise(ActiveRecord::StatementInvalid)
    post event_check_in_path(event), params: { latitude: 30.6, longitude: -96.3 }
    expect(response).to have_http_status(:service_unavailable)
    expect(CGI.unescapeHTML(response.body)).to include("Check-in couldn't be saved", "Check in using my location")
    expect(Attendance.count).to eq(0)
    expect(Point.count).to eq(0)
    expect(member.reload.total_points).to eq(0)
  end

  it "does not allow anonymous check-in submissions" do
    post event_check_in_path(event), params: { latitude: 30.6, longitude: -96.3 }
    expect(response).to redirect_to(new_member_session_path)
    expect(Attendance.count).to eq(0)
    expect(Point.count).to eq(0)
  end

  it "does not mark attendance just by opening a link" do
    sign_in member
    get event_check_in_path(event)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Check in using my location")
    expect(Attendance.count).to eq(0)
    expect(Point.count).to eq(0)
  end

  it "marks the signed-in member present and ignores client-supplied points and member IDs" do
    sign_in member
    other = create(:member)
    post event_check_in_path(event), params: {
      latitude: 30.6, longitude: -96.3, member_id: other.id, points_awarded: 999
    }
    expect(response).to redirect_to(event_check_in_path(event))
    follow_redirect!
    expect(CGI.unescapeHTML(response.body)).to include("You're marked present", "2 points added")
    expect(member.reload.total_points).to eq(2)
    expect(other.reload.total_points).to eq(0)
    expect(Attendance.find_by!(member: member, event: event).checked_in_at).to be_present
  end

  it "adds the points to the event's point type" do
    sign_in member
    post event_check_in_path(event), params: { latitude: 30.6, longitude: -96.3 }

    expect(member.reload.points_by_requirement).to eq(service.id => 2)
    expect(Point.last.requirement).to eq(service)
    expect(flash[:notice]).to include("added to Service")
  end

  it "records attendance but awards nothing for an event with no point type" do
    untyped = create(:event, :check_in_ready, latitude: 30.6, longitude: -96.3, point_value: 2, requirement: nil)
    sign_in member
    post event_check_in_path(untyped), params: { latitude: 30.6, longitude: -96.3 }

    expect(Attendance.find_by!(member: member, event: untyped).checked_in_at).to be_present
    expect(Point.count).to eq(0)
  end

  it "reports duplicate submissions without awarding more points" do
    sign_in member
    2.times { post event_check_in_path(event), params: { latitude: 30.6, longitude: -96.3 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("already checked in")
    expect(member.reload.total_points).to eq(2)
    expect(Point.where(member: member).count).to eq(1)
    expect(Attendance.where(member: member, event: event).count).to eq(1)
  end

  it "explains distance failures and allows another attempt" do
    sign_in member
    post event_check_in_path(event), params: { latitude: 31, longitude: -96.3 }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("not nearby", "Check in using my location")
    expect(member.reload.total_points).to eq(0)
    expect(Attendance.count).to eq(0)
  end

  it "rejects missing location" do
    sign_in member
    post event_check_in_path(event)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("valid location is required")
    expect(Attendance.count).to eq(0)
    expect(Point.count).to eq(0)
  end

  it "uses the event's proximity in feet for the nearby check" do
    sign_in member
    event.update!(check_in_radius_feet: 250) # 250 ft = 76.2 m

    # ~200 ft (61 m) north of the event: inside a 250 ft radius.
    post event_check_in_path(event), params: { latitude: 30.6 + 0.00055, longitude: -96.3 }
    expect(Attendance.where(member: member, event: event).count).to eq(1)

    # A second member ~400 ft (122 m) north is outside the same radius.
    far_member = create(:member, :profile_completed)
    sign_in far_member
    post event_check_in_path(event), params: { latitude: 30.6 + 0.00110, longitude: -96.3 }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("not nearby")
    expect(Attendance.where(member: far_member, event: event).count).to eq(0)
  end

  it "does not change another event's check-in radius" do
    nearby_event = create(:event, check_in_radius_feet: 500, latitude: 30.6, longitude: -96.3,
                                   requirement: nil, point_value: 0)
    sign_in member

    # ~400 ft (122 m) away: too far for the 328 ft default event, close enough for 500 ft.
    post event_check_in_path(nearby_event), params: { latitude: 30.6 + 0.00110, longitude: -96.3 }
    expect(Attendance.where(member: member, event: nearby_event).count).to eq(1)

    post event_check_in_path(event), params: { latitude: 30.6 + 0.00110, longitude: -96.3 }
    expect(response).to have_http_status(:unprocessable_content)
    expect(Attendance.where(member: member, event: event).count).to eq(0)
  end

  it "explains when officers have not configured check-in" do
    sign_in member
    event.update_columns(latitude: nil, longitude: nil) # legacy row: validation would now block this
    get event_check_in_path(event)
    expect(response.body).to include("not configured")
    expect(response.body).not_to include("Check in using my location")
  end

  it "renders an officer-only QR code with the matching event link" do
    sign_in officer
    get check_in_qr_event_path(event)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data:image/svg+xml;base64,", event_check_in_path(event))
    sign_out officer
    sign_in member
    get check_in_qr_event_path(event)
    expect(response).to redirect_to(events_path)
  end

  it "redirects officers to configure an event before displaying a QR code" do
    sign_in officer
    event.update_columns(latitude: nil, longitude: nil) # legacy row: validation would now block this
    get check_in_qr_event_path(event)
    expect(response).to redirect_to(edit_event_path(event))
  end

  it "lets officers configure check-in but prevents members changing settings" do
    sign_in officer
    get edit_event_path(event)
    expect(response.body).to include("event_latitude", "event_longitude", "event_point_value", "event_requirement_id")
    patch event_path(event), params: { event: { latitude: 30.5, longitude: -96.2, point_value: 3, check_in_radius_feet: 250 } }
    expect(event.reload.point_value).to eq(3)
    expect(event.latitude.to_f).to eq(30.5)
    expect(event.longitude.to_f).to eq(-96.2)
    expect(event.check_in_radius_feet).to eq(250)
    expect(event.check_in_radius_meters).to eq(76)
    sign_out officer
    sign_in member
    patch event_path(event), params: { event: { point_value: 999 } }
    expect(response).to redirect_to(events_path)
    expect(event.reload.point_value).to eq(3)
  end
end
