# spec/requests/home_member_info_spec.rb
require "rails_helper"

RSpec.describe "Home page member info", type: :request do
  let(:role) { Role.create!(description: "member") }
  let!(:service) { Requirement.create!(name: "Service", minimum_points: 3) }
  let!(:member) do
    Member.create!(
      uid: "111222",
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      role: role,
      paid_dues: true,
      car_pool_status: true,
      joined_at: Date.new(2024, 8, 15),
      profile_completed_at: Time.current,
      pt_school_application_date: Date.new(2027, 1, 1)
    )
  end

  before do
    member.point_entries.create!(requirement: service, point_amount: 12, awarded_date: Date.current)
    sign_in member
  end

  it "displays all of the signed-in member's information" do
    get root_path

    expect(response.body).to include(member.first_name)
    expect(response.body).to include(member.email)
    expect(response.body).to include(member.role.description)
    expect(response.body).to include(member.joined_at.strftime("%b %Y")).or include(member.joined_at.to_s)
  end

  it "displays total points and progress for each point type" do
    get root_path

    expect(response.body).to include("Total points")
    expect(response.body).to include(member.reload.total_points.to_s)
    expect(response.body).to include("Service points")
    expect(response.body).to include("12 / 3")
  end

  it "shows the member as active when dues are paid and every minimum is met" do
    get root_path

    expect(response.body).to include("status-active")
  end
end
