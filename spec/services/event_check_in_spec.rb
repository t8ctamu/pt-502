require "rails_helper"

RSpec.describe EventCheckIn do
     let(:requirement) { create(:requirement, name: "Service", minimum_points: 3) }
     let(:event) do
          create(:event, :check_in_ready, latitude: 30.6, longitude: -96.3,
                 point_value: 2, requirement: requirement)
     end
     let(:member) { create(:member, :profile_completed) }

     describe "the default web check-in path" do
          it "rejects a check-in from outside the event radius" do
               expect do
                    described_class.call(member: member, event: event, latitude: 31, longitude: -96.3)
               end.to raise_error(EventCheckIn::Rejected, /not nearby/)
          end

          it "records attendance and awards points when inside the radius" do
               attendance = described_class.call(member: member, event: event, latitude: 30.6, longitude: -96.3)

               expect(attendance.checked_in_at).to be_present
               expect(member.reload.total_points).to eq(2)
               expect(Point.last.awarded_date).to eq(Date.current)
          end
     end

     describe "skip_distance: true" do
          it "persists attendance and awards points with no valid location" do
               attendance = described_class.call(member: member, event: event, skip_distance: true)

               expect(attendance).to be_persisted
               expect(attendance.checked_in_at).to be_present
               expect(member.reload.total_points).to eq(2)
               expect(Point.last.awarded_date).to eq(Date.current)
          end

          it "still rejects a member who already checked in" do
               described_class.call(member: member, event: event, skip_distance: true)

               expect do
                    described_class.call(member: member, event: event, skip_distance: true)
               end.to raise_error(EventCheckIn::Rejected, /already checked in/)
          end

          it "still rejects an event that is not configured for check-in" do
               event.update_columns(latitude: nil, longitude: nil)

               expect do
                    described_class.call(member: member, event: event, skip_distance: true)
               end.to raise_error(EventCheckIn::Rejected, /not configured/)
          end
     end

     describe "checked_in_at:" do
          it "persists the supplied timestamp instead of the current time" do
               timestamp = Time.zone.parse("2026-10-06 22:33:31")

               attendance = described_class.call(member: member, event: event,
                                                  skip_distance: true, checked_in_at: timestamp)

               expect(attendance.checked_in_at).to eq(timestamp)
          end

          it "defaults to the current time when not supplied" do
               attendance = described_class.call(member: member, event: event, skip_distance: true)

               expect(attendance.checked_in_at).to be_within(1.minute).of(Time.current)
          end
     end
end
