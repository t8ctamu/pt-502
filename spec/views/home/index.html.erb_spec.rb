require "rails_helper"

RSpec.describe "home/index.html.erb", type: :view do
  let!(:service) { create(:requirement, name: "Service", minimum_points: 3) }
  let!(:social)  { create(:requirement, name: "Social", minimum_points: 2) }

  def stub_current_member(member)
    without_partial_double_verification do
      allow(view).to receive(:current_member).and_return(member)
    end
  end

  before { assign(:upcoming_events, []) }

  it "renders the Not Active badge and missing text for a member below a minimum" do
    member = create(:member, :paid)
    create(:point, member: member, requirement: social, point_amount: 30)
    stub_current_member(member)

    render

    expect(rendered).to have_css(".status-inactive", text: "Not Active Member")
    expect(rendered).to have_css(".status-missing", text: "Needs 3 more service points")
  end

  it "renders the Active badge when everything is met" do
    member = create(:member, :paid)
    create(:point, member: member, requirement: service, point_amount: 3)
    create(:point, member: member, requirement: social, point_amount: 2)
    stub_current_member(member)

    render

    expect(rendered).to have_css(".status-active", text: "Active Member")
    expect(rendered).not_to have_css(".status-missing")
  end

  it "renders one progress stat per required type plus a total" do
    member = create(:member, :paid)
    create(:point, member: member, requirement: service, point_amount: 1)
    stub_current_member(member)

    render
    expect(rendered).to have_css(".stat-label", text: "Total points")
    expect(rendered).to have_css(".stat-label", text: "Service points")
    expect(rendered).to have_css(".stat-label", text: "Social points")
    expect(rendered).to include("1 / 3")
    expect(rendered).to include("0 / 2")
  end

  it "explains the total points required" do
    AppSetting.current.update!(total_points_required: 7)
    stub_current_member(create(:member, :paid))
    render
    expect(rendered).to have_content("7 points in total")
  end

  it "shows officer tools to admins, with no member badge" do
    stub_current_member(create(:member, :admin))
    render

    expect(rendered).to have_link("Member dashboard")
  expect(rendered).not_to have_link("Point settings")
  end
  
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

  it "shows the Point settings link to managers" do
    manager = create(:member, role: Role.find_or_create_by!(description: "Manager"),
                              profile_completed_at: Time.current)
    allow(view).to receive(:current_member).and_return(manager)
    render
    expect(rendered).to have_link("Point settings", href: point_settings_path)
  end
end
