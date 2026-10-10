require "rails_helper"

RSpec.describe "event_check_ins/show", type: :view do
     let!(:service) { create(:requirement, name: "Service", minimum_points: 1) }
  let(:event)    { create(:event, :check_in_ready, requirement: service, point_value: 2) }
  let(:member)   { create(:member, :profile_completed) }

  before do
       assign(:event, event)
    without_partial_double_verification do
         allow(view).to receive(:current_member).and_return(member)
    end
  end

  it "shows the point type before check-in" do
       assign(:attendance, nil)
    render
    expect(rendered).to include("2 points (Service)")
  end

  it "shows points awarded, total and Active status after check-in" do
       attendance = EventCheckIn.call(member: member, event: event,
         latitude: event.latitude.to_f, longitude: event.longitude.to_f)
    assign(:attendance, attendance)

    render

    expect(rendered).to include("Points awarded: 2")
    expect(rendered).to include("Your total: 2")
    expect(rendered).to include("Status: Active")
  end

  it "shows Inactive and what is missing when another type is short" do
       create(:requirement, name: "Social", minimum_points: 2)
    attendance = EventCheckIn.call(member: member, event: event,
      latitude: event.latitude.to_f, longitude: event.longitude.to_f)
    assign(:attendance, attendance)

    render

    expect(rendered).to include("Status: Inactive")
    expect(rendered).to include("needs 2 more social points")
  end

  it "shows the error message when check-in was rejected" do
       assign(:attendance, nil)
    assign(:check_in_error, "You are not nearby. Move closer to the event and try again.")
    render
    expect(rendered).to have_css("[role=alert]", text: "You are not nearby")
  end
end
