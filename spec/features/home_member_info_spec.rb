# spec/requests/home_member_info_spec.rb
require "rails_helper"

RSpec.describe "Home page member info", type: :request do
  let(:role) { Role.create!(description: "member") }
  let!(:member) do
    Member.create!(
      uid: "111222",
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      role: role,
      points: 12,
      paid_dues: true,
      car_pool_status: true,
      joined_at: Date.new(2024, 8, 15),
      profile_completed_at: Time.current,
      pt_school_application_date: Date.new(2027, 1, 1)
    )
  end

  before { sign_in member }

  it "displays all of the signed-in member's information" do
    get root_path

    expect(response.body).to include(member.first_name)
    expect(response.body).to include(member.email)
    expect(response.body).to include(member.points.to_s)
    expect(response.body).to include(member.role.description)
    expect(response.body).to include(member.joined_at.strftime("%b %Y")).or include(member.joined_at.to_s)
  end
end
