require "rails_helper"

RSpec.describe "Normalized event locations" do
     it "stores venue data only in the associated location" do
          event = create(:event, location: "Clinic", latitude: 30.61, longitude: -96.34)
       expect(Event.column_names).not_to include("location", "latitude", "longitude")
       expect(event.reload.saved_location).to have_attributes(name: "Clinic", is_saved: false)
       expect(event.latitude.to_f).to eq(30.61)
     end

  it "keeps an unpinned imported venue out of the reusable list" do
       event = create(:event, location: "Online", latitude: nil, longitude: nil)
    expect(event.reload.location).to eq("Online")
    expect(event.check_in_configured?).to be false
    expect(SavedLocation.reusable).not_to include(event.saved_location)
  end

  it "does not move other events when editing a shared venue" do
       venue = SavedLocation.create!(name: "Clinic", latitude: 30.61, longitude: -96.34)
    first = create(:event)
    second = create(:event)
    first.update!(saved_location: venue)
    second.update!(saved_location: venue)

    first.update!(location: "New clinic", latitude: 31, longitude: -97)
    expect(first.reload.location).to eq("New clinic")
    expect(second.reload.location).to eq("Clinic")
    expect(venue.reload.latitude.to_f).to eq(30.61)
    expect(venue.is_saved?).to be true
  end

  it "rejects a malformed pin without persisting a location" do
       event = build(:event, latitude: "abc", longitude: -96)
    expect { event.save }.not_to change(SavedLocation, :count)
    expect(event).not_to be_persisted
  end

  it "protects a referenced location from deletion" do
       event = create(:event)
    expect(event.saved_location.destroy).to be false
    expect(event.reload.saved_location).to be_present
  end
end
