require "rails_helper"

RSpec.describe Event, type: :model do
  it "requires a location pin, so every new event has check-in configured" do
    expect(build(:event)).to be_check_in_configured

    event = build(:event, latitude: nil, longitude: nil)
    expect(event).not_to be_valid
    expect(event.errors[:base]).to include("Choose a location on the map before saving.")
  end

  it "belongs to a requirement" do
    expect(described_class.reflect_on_association(:requirement).macro).to eq(:belongs_to)
  end

  it "is valid with a requirement (point type)" do
    expect(build(:event, requirement: create(:requirement, name: "Service"))).to be_valid
  end

  it "exposes the point type through the association" do
    service = create(:requirement, name: "Service")
    expect(create(:event, requirement: service).requirement.name).to eq("Service")
  end

  # Remove this example once you switch to a required `belongs_to :requirement`
  it "currently allows an event with no point type" do
    expect(build(:event, requirement: nil)).to be_valid
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

    it "requires ends_at to be after starts_at" do
    event = build(:event, starts_at: Time.current, ends_at: 1.hour.ago)
    expect(event).not_to be_valid
    expect(event.errors[:base]).to include("End time must be after the start time")
  end

  it "is valid when ends_at is after starts_at" do
    event = build(:event, starts_at: Time.current, ends_at: 1.hour.from_now)
    expect(event).to be_valid
  end
end


require "rails_helper"
