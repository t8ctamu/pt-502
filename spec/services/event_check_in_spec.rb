require "rails_helper"

RSpec.describe EventCheckIn do
  let(:member) { create(:member, points: 4) }
  let(:event) { create(:event, latitude: 30.6, longitude: -96.3, point_value: 2) }

  def check_in(**overrides)
    described_class.call(**{ member: member, event: event, latitude: 30.6, longitude: -96.3 }.merge(overrides))
  end

  it "records a nearby member and awards the event's points" do
    attendance = check_in(latitude: 30.6001)
    expect(attendance.checked_in_at).to be_present
    expect(attendance.points_awarded).to eq(2)
    expect(member.reload.points).to eq(6)
  end

  it "rejects a duplicate without changing the original timestamp or awarding points again" do
    attendance = check_in
    original_time = attendance.checked_in_at
    expect { check_in }.to raise_error(EventCheckIn::Rejected, /already checked in/)
    expect(member.reload.points).to eq(6)
    expect(attendance.reload.checked_in_at).to eq(original_time)
    expect(Attendance.where(member: member, event: event).count).to eq(1)
  end

  it "checks in an existing unconfirmed attendance record" do
    attendance = create(:attendance, member: member, event: event)
    expect { check_in }.not_to change(Attendance, :count)
    expect(attendance.reload.checked_in_at).to be_present
    expect(member.reload.points).to eq(6)
  end

  it "rejects distant members without recording attendance or points" do
    expect { check_in(latitude: 31) }.to raise_error(EventCheckIn::Rejected, /not nearby/)
    expect(Attendance.where(member: member)).to be_empty
    expect(member.reload.points).to eq(4)
  end

  it "requires authentication" do
    expect { check_in(member: nil) }.to raise_error(EventCheckIn::Rejected, /sign in/)
  end

  it "rejects events without coordinates" do
    event.update_columns(latitude: nil, longitude: nil) # legacy row: validation would now block this
    expect { check_in }.to raise_error(EventCheckIn::Rejected, /not configured/)
    expect(member.reload.points).to eq(4)
  end

  it "rejects missing, malformed, nonfinite, and out-of-range locations" do
    [ nil, "", "wrong", Float::INFINITY, Float::NAN, 91 ].each do |latitude|
      expect { check_in(latitude: latitude) }.to raise_error(EventCheckIn::Rejected, /valid location/)
    end
    expect { check_in(longitude: -181) }.to raise_error(EventCheckIn::Rejected, /valid location/)
    expect(Attendance.where(member: member)).to be_empty
    expect(member.reload.points).to eq(4)
  end

  it "rolls attendance back if the points update fails" do
    allow(member).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(member))
    expect { check_in }.to raise_error(ActiveRecord::RecordInvalid)
    expect(Attendance.where(member: member)).to be_empty
    expect(member.reload.points).to eq(4)
  end

  it "awards points separately for different events" do
    check_in
    check_in(event: create(:event, latitude: 30.6, longitude: -96.3, point_value: 3))
    expect(member.reload.points).to eq(9)
  end
end