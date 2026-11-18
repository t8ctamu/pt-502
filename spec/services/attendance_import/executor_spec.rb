require "rails_helper"

RSpec.describe AttendanceImport::Executor do
     let(:requirement) { create(:requirement, name: "Service") }
     let(:event) do
          create(:event, :check_in_ready, latitude: 30.6, longitude: -96.3,
                 point_value: 2, requirement: requirement)
     end
     let(:member) { create(:member, :profile_completed) }
     let(:other_member) { create(:member, :profile_completed) }

     def ready_row(member:, index: 2, checked_in_at: Time.zone.parse("2026-10-06 22:33:31"))
          AttendanceImport::Mapper::Row.new(
               index: index, raw: [], email: member.email, checked_in_at: checked_in_at,
               member: member, status: :ready, errors: []
          )
     end

     def error_row(index: 3, email: "ghost@email.tamu.edu")
          AttendanceImport::Mapper::Row.new(
               index: index, raw: [], email: email, checked_in_at: nil,
               member: nil, status: :error, errors: [ "No member found for #{email}" ]
          )
     end

     it "saves a ready row and awards points" do
          result = described_class.new(rows: [ ready_row(member: member) ], event: event).call

          expect(result.saved).to eq(1)
          expect(result.errors).to be_empty
          expect(Attendance.where(member: member, event: event).count).to eq(1)
          expect(member.reload.total_points).to eq(2)
          expect(Point.last.awarded_date).to eq(Date.current)
     end

     it "imports valid rows while collecting a bad row (partial import)" do
          rows = [ ready_row(member: member), error_row, ready_row(member: other_member, index: 4) ]

          result = described_class.new(rows: rows, event: event).call

          expect(result.saved).to eq(2)
          expect(result.errors.map(&:index)).to eq([ 3 ])
          expect(Attendance.where(event: event).count).to eq(2)
     end

     it "reports a member who is already checked in without awarding twice" do
          described_class.new(rows: [ ready_row(member: member) ], event: event).call

          result = described_class.new(rows: [ ready_row(member: member) ], event: event).call

          expect(result.saved).to eq(0)
          expect(result.errors.size).to eq(1)
          expect(result.errors.first.errors).to include(/already checked in/)
          expect(Point.where(member: member).count).to eq(1)
          expect(Attendance.where(member: member, event: event).count).to eq(1)
     end

     it "reports a not-configured event as a row error" do
          event.update_columns(latitude: nil, longitude: nil)

          result = described_class.new(rows: [ ready_row(member: member) ], event: event).call

          expect(result.saved).to eq(0)
          expect(result.errors.first.errors).to include(/not configured/)
     end
end
