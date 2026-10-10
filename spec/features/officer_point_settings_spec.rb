require "rails_helper"

RSpec.feature "Officer edits point requirements", type: :feature do
  include Devise::Test::IntegrationHelpers

  let(:manager)  { create(:member, :profile_completed, :manager) }
  let!(:service)      { create(:requirement, name: "Service", minimum_points: 1) }
  let!(:professional) { create(:requirement, name: "Professional/Development", minimum_points: 1) }
  let!(:social)       { create(:requirement, name: "Social", minimum_points: 1) }

  def fill_minimum(requirement, value)
    fill_in "requirements_#{requirement.id}", with: value
  end

  scenario "officer sees all point types and sets a minimum for each" do
    sign_in manager
    visit point_settings_path

    expect(page).to have_field("requirements_#{service.id}", with: "1")
    expect(page).to have_content("Professional/Development")

    fill_minimum(service, "3")
    fill_minimum(professional, "2")
    fill_minimum(social, "2")
    click_button "Save requirements"

    expect(page).to have_content("Point requirements saved.")
    expect(page).to have_field("requirements_#{service.id}", with: "3")
    expect(page).to have_field("requirements_#{professional.id}", with: "2")
    expect(page).to have_field("requirements_#{social.id}", with: "2")
    expect(Requirement.pluck(:minimum_points)).to match_array([3, 2, 2])
  end

  ["", "-1", "abc", "2.5"].each do |bad|
    scenario "officer enters #{bad.inspect} and sees a clear error without saving" do
      sign_in manager
      visit point_settings_path

      fill_minimum(service, bad)
      click_button "Save requirements"

      expect(page).to have_content("Enter a whole number of 0 or more")
      expect(page).to have_content("No changes were saved.")

      visit point_settings_path
      expect(page).to have_field("requirements_#{service.id}", with: "1")
      expect(service.reload.minimum_points).to eq(1)
    end
  end

  scenario "one bad value blocks the whole save, even for valid fields" do
    sign_in manager
    visit point_settings_path

    fill_minimum(service, "9")
    fill_minimum(social, "oops")
    click_button "Save requirements"

    expect(page).to have_content("Enter a whole number of 0 or more")
    expect(service.reload.minimum_points).to eq(1)
  end

  scenario "a regular member is turned away from the settings page" do
    sign_in create(:member, :profile_completed)
    visit point_settings_path

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Managers only.")
  end

  scenario "officer reaches settings from the home page" do
    sign_in manager
    visit root_path
    click_link "Point settings"

    expect(page).to have_current_path(point_settings_path)
  end
end