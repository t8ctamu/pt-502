require "rails_helper"
RSpec.describe "Member standing", type: :request do
  let!(:service) { create(:requirement, name: "Service", minimum_points: 3) }
  let!(:social)  { create(:requirement, name: "Social", minimum_points: 0) }
  let(:admin)    { create(:member, :admin, :profile_completed, paid_dues: true) }
  let!(:member) do
    create(:member, :profile_completed, first_name: "Jane", last_name: "Doe",
           email: "jane@tamu.edu", paid_dues: true)
  end

  def row_for(target)
    response.body.scan(/<tr[^>]*>.*?<\/tr>/m).find { |row| row.include?(target.email) }
  end

  context "as an admin" do
    before { sign_in admin }

    it "shows Active when every minimum is met and dues are paid" do
      create(:point, member: member, requirement: service, point_amount: 3)
      get members_path

      expect(row_for(member)).to include("status-active")
      expect(row_for(member)).not_to include("status-inactive")
    end

    it "shows Not Active and what is missing for a member below a minimum" do
      get members_path

      expect(row_for(member)).to include("status-inactive")
      expect(row_for(member)).to include("Needs 3 more service points")
    end

    it "still shows Not Active when total points are high but Service is short" do
      create(:point, member: member, requirement: social, point_amount: 50)
      get members_path

      expect(row_for(member)).to include("status-inactive")
      expect(row_for(member)).to include("Needs 3 more service points")
    end

    it "shows Not Active when minimums are met but dues are unpaid" do
      member.update!(paid_dues: false)
      create(:point, member: member, requirement: service, point_amount: 3)
      get members_path

      expect(row_for(member)).to include("status-inactive")
    end

    it "updates dues and cannot be used to assign points" do
      patch member_path(member), params: { member: { paid_dues: "0", points: 8 } }

      expect(response).to redirect_to(members_path)
      expect(member.reload.paid_dues).to be(false)
      expect(Point.where(member: member)).to be_empty
      expect(member.total_points).to eq(0)
    end
  end

  context "as a non-admin" do
    it "does not let a member change another member's dues" do
      other = create(:member, :profile_completed, paid_dues: false)
      sign_in member

      patch member_path(other), params: { member: { paid_dues: "1" } }

      expect(other.reload.paid_dues).to be(false)
    end
  end
end