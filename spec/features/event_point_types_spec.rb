require "rails_helper"

# Field ids assume standard form_with model: @event helpers (event_name, event_location, ...).
# Adjust the ids below if your form uses custom ids.
RSpec.feature "Officer assigns a point type to an event", type: :feature do
     include Devise::Test::IntegrationHelpers

  let(:admin) { create(:member, :profile_completed, :admin) }
  let!(:service) { create(:requirement, name: "Service", minimum_points: 3) }
  let!(:social)  { create(:requirement, name: "Social", minimum_points: 2) }

 scenario "creating a service event" do
     sign_in admin
  visit new_event_path

  fill_in "event_name", with: "Food Bank Shift"
  fill_in "event_location", with: "Bryan"
  find("#event_latitude", visible: false).set("30.6744")
  find("#event_longitude", visible: false).set("-96.3698")
  fill_in "event_starts_at", with: "2026-11-01T10:00"
  fill_in "event_point_value", with: "2"
  # Other fields your form may require; only filled in when the form has them
  {
    "event_description" => "Sorting donated cans",
    "event_ends_at" => "2026-11-01T12:00",
    "event_check_in_radius_feet" => "250"
  }.each { |id, value| fill_in id, with: value if page.has_field?(id) }
  select "Service", from: "event_requirement_id"
  find("form[action='#{events_path}'] [type='submit']").click

  event = Event.find_by(name: "Food Bank Shift")
  expect(event).to be_present, "Event was not saved. The page said: #{page.text}"
  expect(event.requirement).to eq(service)
  expect(event.point_value).to eq(2)
  expect(page).to have_current_path(events_path)
end

  scenario "changing an event's type" do
       event = create(:event, requirement: service)
    sign_in admin
    visit edit_event_path(event)

    select "Social", from: "event_requirement_id"
    find("form[action='#{event_path(event)}'] [type='submit']").click

    expect(event.reload.requirement).to eq(social)
  end

  scenario "the event page tells members what kind of point it earns" do
       event = create(:event, name: "Mixer", requirement: social, point_value: 1)
    sign_in create(:member, :profile_completed)
    visit event_path(event)

    expect(page).to have_content("1 point")
    expect(page).to have_content("Social")
  end
end
