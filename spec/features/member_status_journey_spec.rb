require "rails_helper"

# End-to-end "sunny day": a member earns points across types and their status follows the
# per-type minimums, not the total. The JS location step is skipped by posting coordinates directly.
RSpec.feature "Member status follows per-type minimums", type: :feature do
  include Devise::Test::IntegrationHelpers

  let!(:service)      { create(:requirement, name: "Service", minimum_points: 2) }
  let!(:professional) { create(:requirement, name: "Professional/Development", minimum_points: 1) }
  let!(:social)       { create(:requirement, name: "Social", minimum_points: 1) }
  let(:member)        { create(:member, :profile_completed, :paid) }

  def attend(event)
    page.driver.submit :post, event_check_in_path(event),
      latitude: event.latitude.to_f, longitude: event.longitude.to_f
  end

  scenario "total points alone never make a member active" do
    sign_in member

    visit root_path
    expect(page).to have_css(".status-inactive")
    expect(page).to have_content(/needs 2 more service points/i)
    expect(page).to have_content(/needs 1 more professional\/development point/i)
    expect(page).to have_content(/needs 1 more social point/i)

    # Lots of social points: total is high, but service and development are still missing
    attend(create(:event, :check_in_ready, requirement: social, point_value: 10))
    visit root_path

    expect(page).to have_css(".status-inactive")
    expect(page).to have_content(/needs 2 more service points/i)
    expect(page).not_to have_content(/needs \d more social/i)
    expect(page).to have_content("10 / 1")

    # Meet service and development: now active
    attend(create(:event, :check_in_ready, requirement: service, point_value: 2))
    visit root_path
    expect(page).to have_css(".status-inactive")
    expect(page).to have_content(/needs 1 more professional\/development point/i)

    attend(create(:event, :check_in_ready, requirement: professional, point_value: 1))
    visit root_path

    expect(page).to have_css(".status-active")
    expect(page).not_to have_css(".status-inactive")
    expect(Member.find(member.id).total_points).to eq(13)
  end

  scenario "the member sees points land in the right type after checking in" do
    sign_in member
    event = create(:event, :check_in_ready, requirement: service, point_value: 1)

    attend(event)
    visit root_path

    expect(page).to have_content("1 / 2")
    expect(page).to have_content(/needs 1 more service point/i)
    expect(Point.last.requirement).to eq(service)
  end

  scenario "a second check-in at the same event is refused" do
    sign_in member
    event = create(:event, :check_in_ready, requirement: service, point_value: 1)

    attend(event)
    attend(event)

    expect(page).to have_content("You have already checked in to this event.")
    expect(Point.where(member: member).count).to eq(1)
  end

  scenario "an officer raising a minimum flips an active member to inactive" do
    create(:point, member: member, requirement: service, point_amount: 2)
    create(:point, member: member, requirement: professional, point_amount: 1)
    create(:point, member: member, requirement: social, point_amount: 1)

    sign_in member
    visit root_path
    expect(page).to have_css(".status-active")

    service.update!(minimum_points: 3)
    visit root_path
    expect(page).to have_css(".status-inactive")
    expect(page).to have_content(/needs 1 more service point/i)
  end
end