require "rails_helper"

RSpec.describe "Concurrent event check-in", type: :model do
  self.use_transactional_tests = false

  it "records one attendance and one point award when two scans arrive together" do
    member = create(:member, points: 4)
    event = create(:event, latitude: 30.6, longitude: -96.3, point_value: 2)
    ready = Queue.new
    start = Queue.new
    workers = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          local_member = Member.find(member.id)
          local_event = Event.find(event.id)
          ready << true
          start.pop
          begin
            EventCheckIn.call(member: local_member, event: local_event, latitude: 30.6, longitude: -96.3)
            :saved
          rescue EventCheckIn::Rejected
            :duplicate
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }

    expect(workers.map(&:value)).to contain_exactly(:saved, :duplicate)
    expect(Attendance.where(member: member, event: event).count).to eq(1)
    expect(member.reload.points).to eq(6)
  ensure
    workers&.each(&:join)
    event&.destroy!
    member&.destroy!
  end
end
