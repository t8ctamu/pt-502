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

  describe "associations" do
    it "optionally belongs to a point" do
      attendance = build(:attendance, point: nil)
      expect(attendance).to be_valid
      expect(described_class.reflect_on_association(:point).macro).to eq(:belongs_to)
    end
  end

  describe "uniqueness" do
    it "prevents a member from checking in to the same event twice" do
      first = create(:attendance)
      duplicate = build(:attendance, member: first.member, event: first.event)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:member_id]).to include("has already checked in to this event")
    end

    it "allows the same member at different events" do
      member = create(:member)
      create(:attendance, member: member)
      expect(build(:attendance, member: member)).to be_valid
    end
  end

  describe "#points_awarded" do
    it "returns the amount on the linked point" do
      point = create(:point, point_amount: 3)
      expect(build(:attendance, point: point).points_awarded).to eq(3)
    end

    it "returns 0 when no point was awarded" do
      expect(build(:attendance, point: nil).points_awarded).to eq(0)
    end

    it "keeps the original amount when the event is edited later" do
      member = create(:member)
      requirement = create(:requirement)
      event = create(:event, requirement: requirement, point_value: 2)
      point = create(:point, member: member, requirement: requirement, point_amount: 2)
      attendance = create(:attendance, member: member, event: event, point: point)

      event.update!(point_value: 9)

      expect(attendance.reload.points_awarded).to eq(2)
    end
  end
end

require "rails_helper"

