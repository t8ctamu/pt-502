# spec/requests/member_standing_spec.rb
require "rails_helper"

RSpec.describe "Editing member points", type: :request do
  let(:admin_role) { Role.create!(description: "Admin") }
  let!(:admin) do
    Member.create!(
      uid: "123545",
      first_name: "Ad",
      last_name: "Min",
      email: "admin@example.com",
      role: admin_role,
      points: 0,
      paid_dues: true,
      profile_completed_at: Time.current
    )
  end

  let(:member_role) { Role.create!(description: "member") }
  let!(:member) do
    Member.create!(
      uid: "987654",
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      role: member_role,
      points: 3,
      paid_dues: false,
      profile_completed_at: Time.current
    )
  end

  context "as an admin" do
    before { sign_in admin }

    it "updates points and reflects it on the members page" do
      patch member_path(member), params: { member: { points: 8 } }

      puts "STATUS: #{response.status}"
    puts "LOCATION: #{response.headers['Location']}" if response.redirect?
    puts response.body if response.status >= 400 && response.status != 302

      member.reload
      expect(member.points).to eq(8)

      get members_path
      member_row = response.body[/<tr>.*?#{Regexp.escape(member.email)}.*?<\/tr>/m]
      expect(member_row).to include("8")
    end
  end

  context "as a non-admin" do
    before { sign_in member }

    it "does not update another member's points" do
      other = Member.create!(
        uid: "555555",
        first_name: "Sam",
        last_name: "Lee",
        email: "sam@example.com",
        role: member_role,
        points: 2,
        paid_dues: false,
        profile_completed_at: Time.current
      )

      patch member_path(other), params: { member: { points: 8 } }

      other.reload
      expect(other.points).to eq(2)
    end
  end
end