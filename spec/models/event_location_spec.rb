require "rails_helper"

RSpec.describe EventLocationValidations do
  # Adjust to the attributes your Event needs to be otherwise valid.
  let(:attributes) do
    {
      name: "Weekly meeting", starts_at: 2.days.from_now,
      location: "Student Center, 100 Campus Dr",
      latitude: 30.61, longitude: -96.34,
      check_in_radius_meters: 100, point_value: 1
    }
  end

  it "is valid with a name and coordinates" do
    expect(Event.new(attributes)).to be_valid
  end

  it "requires a readable location name" do
    event = Event.new(attributes.merge(location: ""))
    expect(event).not_to be_valid
    expect(event.errors[:location]).to be_present
  end

  it "requires both coordinates" do
    event = Event.new(attributes.merge(latitude: nil))
    expect(event).not_to be_valid
    expect(event.errors[:base]).to include("Choose a location on the map before saving.")
  end

  it "rejects out-of-range coordinates" do
    expect(Event.new(attributes.merge(latitude: 90.5))).not_to be_valid
    expect(Event.new(attributes.merge(longitude: -180.5))).not_to be_valid
  end
end

RSpec.describe SavedLocation do
  it "is valid with a name and coordinates" do
    expect(described_class.new(name: "PT Clinic", latitude: 30.62, longitude: -96.33)).to be_valid
  end

  it "requires a unique name and in-range coordinates" do
    described_class.create!(name: "PT Clinic", latitude: 30.62, longitude: -96.33)

    expect(described_class.new(name: "pt clinic", latitude: 30.6, longitude: -96.3)).not_to be_valid
    expect(described_class.new(name: "Gym", latitude: 95, longitude: -96.3)).not_to be_valid
    expect(described_class.new(name: "", latitude: 30.6, longitude: -96.3)).not_to be_valid
  end
end
