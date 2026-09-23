require "rails_helper"

RSpec.describe Attendance, type: :model do
  it "rejects a second attendance for the same member and event" do
    attendance = create(:attendance)
    duplicate = build(:attendance, member: attendance.member, event: attendance.event)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:member_id]).to include("has already checked in to this event")
  end

  it "allows the same member to attend different events" do
    attendance = create(:attendance)

    expect(create(:attendance, member: attendance.member)).to be_persisted
  end

  it "allows different members to attend the same event" do
    attendance = create(:attendance)

    expect(create(:attendance, event: attendance.event)).to be_persisted
  end

  it "enforces uniqueness in the database even when validation is bypassed" do
    attendance = create(:attendance)
    duplicate = build(:attendance, member: attendance.member, event: attendance.event)

    expect do
      Attendance.transaction(requires_new: true) { duplicate.save!(validate: false) }
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

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
