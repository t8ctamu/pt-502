require "rails_helper"

RSpec.describe Event, type: :model do
  it "requires a location pin, so every new event has check-in configured" do
  expect(build(:event)).to be_check_in_configured

  event = build(:event, latitude: nil, longitude: nil)
  expect(event).not_to be_valid
  expect(event.errors[:base]).to include("Choose a location on the map before saving.")
end

  it "requires coordinates together and within geographic bounds" do
    expect(build(:event, latitude: 30, longitude: nil)).not_to be_valid
    expect(build(:event, latitude: nil, longitude: -96)).not_to be_valid
    expect(build(:event, latitude: 91, longitude: 0)).not_to be_valid
    expect(build(:event, latitude: 0, longitude: -181)).not_to be_valid
    expect(build(:event, latitude: 0, longitude: 0)).to be_valid
  end

  it "requires nonnegative integer points and a positive integer radius" do
    expect(build(:event, point_value: -1)).not_to be_valid
    expect(build(:event, point_value: 1.5)).not_to be_valid
    expect(build(:event, check_in_radius_meters: 0)).not_to be_valid
    expect(build(:event, check_in_radius_meters: 1.5)).not_to be_valid
    expect(build(:event, point_value: 0)).to be_valid
  end

  it "can be created" do
    expect(create(:event)).to be_persisted
  end
end
