require "rails_helper"

RSpec.describe "home/index.html.erb", type: :view do
  it "shows officer tools for an admin" do
    admin = build_stubbed(:member, :admin, :profile_completed)
    allow(view).to receive(:current_member).and_return(admin)

    render

    expect(rendered).to include("Officer tools")
    expect(rendered).to include("Member dashboard")
  end

  it "hides officer tools for a non-admin member" do
    member = build_stubbed(:member, :profile_completed)
    allow(view).to receive(:current_member).and_return(member)

    render

    expect(rendered).not_to include("Officer tools")
  end
end
