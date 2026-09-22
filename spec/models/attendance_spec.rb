require "rails_helper"

RSpec.describe Attendance, type: :model do
  it "belongs to a member" do
    expect(Attendance.reflect_on_association(:member).macro).to eq(:belongs_to)
  end

  it "belongs to an event" do
    expect(Attendance.reflect_on_association(:event).macro).to eq(:belongs_to)
  end

  it "can be created with a member and an event" do
    attendance = create(:attendance)
    expect(attendance).to be_persisted
    expect(attendance.member).to be_a(Member)
    expect(attendance.event).to be_a(Event)
  end
end