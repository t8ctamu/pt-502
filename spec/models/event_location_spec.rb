require "rails_helper"

RSpec.describe Event do
     it "is valid with a name and a pin" do
          expect(build(:event, location: "Student Center, 100 Campus Dr",
                               latitude: 30.61, longitude: -96.34)).to be_valid
     end

  it "allows a named venue without a pin when the map is unavailable" do
       event = build(:event, latitude: nil, longitude: nil)

    expect(event).to be_valid
    expect(event.check_in_configured?).to be false
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
