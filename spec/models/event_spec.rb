require "rails_helper"

RSpec.describe Event, type: :model do
  it "allows a named event without a pin while leaving check-in unconfigured" do
    expect(build(:event)).to be_check_in_configured

    event = build(:event, latitude: nil, longitude: nil)
    expect(event).to be_valid
    expect(event).not_to be_check_in_configured
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

  it "requires nonnegative integer points and a valid check-in proximity in feet" do
    expect(build(:event, point_value: -1)).not_to be_valid
    expect(build(:event, point_value: 1.5)).not_to be_valid
    expect(build(:event, point_value: 0)).to be_valid
    expect(build(:event, check_in_radius_feet: 100)).to be_valid
    expect(build(:event, check_in_radius_feet: 250)).to be_valid
    expect(build(:event, check_in_radius_feet: 1000)).to be_valid
  end

  describe "check_in_radius_feet" do
    it "defaults to 250 feet" do
      expect(Event.new.check_in_radius_feet).to eq(250)
    end

    it "rejects a blank value with the blank message" do
      event = build(:event, check_in_radius_feet: nil)
      expect(event).not_to be_valid
      expect(event.errors[:check_in_radius_feet]).to include(Event::CHECK_IN_RADIUS_FEET_BLANK_MESSAGE)
    end

    it "rejects words and non-whole numbers with the whole-number message" do
      [ "abc", 1.5, "12ft" ].each do |feet|
        event = build(:event, check_in_radius_feet: feet)
        expect(event).not_to be_valid
        expect(event.errors[:check_in_radius_feet]).to include(Event::CHECK_IN_RADIUS_FEET_WHOLE_NUMBER_MESSAGE)
      end
    end

    it "rejects out-of-range values with the range message" do
      [ 0, -5, 99, 1001 ].each do |feet|
        event = build(:event, check_in_radius_feet: feet)
        expect(event).not_to be_valid
        expect(event.errors[:check_in_radius_feet]).to include(Event::CHECK_IN_RADIUS_FEET_RANGE_MESSAGE)
      end
    end
  end

  it "can be created" do
    expect(create(:event)).to be_persisted
  end
end
