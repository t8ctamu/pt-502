require "rails_helper"

# Event itself already tests name presence, coordinate bounds and pairing
# (spec/models/event_spec.rb). These cover only what the location picker added.
RSpec.describe EventLocationValidations do
  it "is valid with a name and a pin" do
    expect(build(:event, location: "Student Center, 100 Campus Dr",
                         latitude: 30.61, longitude: -96.34)).to be_valid
  end

  it "requires a pin" do
    event = build(:event, latitude: nil, longitude: nil)

    expect(event).not_to be_valid
    expect(event.errors[:base]).to include("Choose a location on the map before saving.")
  end

  it "requires a readable location name" do
    event = build(:event, location: "")

    expect(event).not_to be_valid
    expect(event.errors[:location]).to be_present
  end

  it "reports a half-set pin with the existing pairing message" do
    event = build(:event, latitude: 30.61, longitude: nil)

    expect(event).not_to be_valid
    expect(event.errors[:base]).to include("Provide both latitude and longitude")
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