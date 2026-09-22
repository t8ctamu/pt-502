require "rails_helper"

RSpec.describe Event, type: :model do
  it "can be created" do
    expect(create(:event)).to be_persisted
  end
end
