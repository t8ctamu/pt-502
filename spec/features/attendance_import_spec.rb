require "rails_helper"

RSpec.feature "Importing attendance for an event", type: :feature do
     include Devise::Test::IntegrationHelpers

     let(:admin) { create(:member, :admin, :profile_completed) }
     let(:regular) { create(:member, :profile_completed) }

     let!(:service) { create(:requirement, name: "Service", minimum_points: 1) }
     let!(:event) do
          create(:event, :check_in_ready, latitude: 30.6, longitude: -96.3,
                 point_value: 1, requirement: service)
     end

     let!(:mennah) { create(:member, :profile_completed, paid_dues: true, email: "ktmd3368@email.tamu.edu") }
     let!(:trevor) { create(:member, :profile_completed, paid_dues: true, email: "trevorpatton249@email.tamu.edu") }
     let!(:jordan) { create(:member, :profile_completed, paid_dues: true, email: "jordanlee@email.tamu.edu") }

     let(:mixed_csv) { Rails.root.join("spec/fixtures/files/attendance_uat_mixed.csv") }
     let(:missing_columns_csv) { Rails.root.join("spec/fixtures/files/attendance_uat_missing_columns.csv") }
     let(:corrupt_csv) { Rails.root.join("spec/fixtures/files/attendance_uat_corrupt.csv") }
     let(:bad_xlsx) { Rails.root.join("spec/fixtures/files/attendance_uat_bad_xlsx.xlsx") }
          let(:customer_xlsx) { Rails.root.join("spec/fixtures/files/attendance_customer_sample.xlsx") }

     before { AppSetting.current.update!(total_points_required: 1) }

     def upload(path)
          visit upload_attendance_import_path(event)
          attach_file "file", path
          find("form[action='#{attendance_imports_path}'] [type='submit']").click
     end

     scenario "AC1: an officer uploads attendance and sees how many records were saved" do
          sign_in admin
          upload(mixed_csv)
          expect(page).to have_content("3 attendance records saved")
     end

     scenario "AC1: an officer can upload the customer's xlsx export" do
          sign_in admin
          upload(customer_xlsx)

          expect(page).to have_content("2 attendance records saved")

          attendance = Attendance.find_by!(member: mennah, event: event)
          expect(attendance.checked_in_at.hour).to eq(22)
          expect(attendance.checked_in_at.min).to eq(33)
     end

     scenario "AC7: the upload form is labeled" do
          sign_in admin
          visit upload_attendance_import_path(event)
          expect(page).to have_field("Attendance file (.csv or .xlsx)")
     end

     scenario "AC2: imported points move totals and active status" do
          sign_in admin
          expect(mennah.reload.active_status?).to be(false)

          upload(mixed_csv)

          mennah.reload
          expect(mennah.total_points).to eq(1)
          expect(mennah.points_by_requirement).to eq(service.id => 1)
          expect(mennah.active_status?).to be(true)
     end

     scenario "AC2: a member who qualifies sees an active status on their home page" do
          create(:point, member: mennah, requirement: service, point_amount: 1)
          sign_in mennah
          visit root_path

          expect(page).to have_css(".status-active")
     end

     scenario "AC3: a file missing required columns names the problem and saves nothing" do
          sign_in admin
          expect { upload(missing_columns_csv) }.not_to change { Attendance.count }
          expect(page).to have_content("missing required column")
     end

     scenario "AC3: a corrupt csv with a valid extension saves nothing" do
          sign_in admin
          expect { upload(corrupt_csv) }.not_to change { Attendance.count }
          expect(page).to have_content(/missing required column|could not be read/i)
     end

     scenario "AC3: a file with an xlsx name that is not a spreadsheet saves nothing" do
          sign_in admin
          expect { upload(bad_xlsx) }.not_to change { Attendance.count }
          expect(page).to have_content(/could not be read/i)
     end

     scenario "AC4: valid rows save while bad rows are listed with row number and reason" do
          sign_in admin
          upload(mixed_csv)
          expect(page).to have_content("3 attendance records saved")
          expect(page).to have_content("ghost@email.tamu.edu")
          expect(page).to have_content("already checked in")
          expect(Attendance.where(event: event).count).to eq(3)
          expect(Attendance.where(event: event, member: mennah).count).to eq(1)
     end

     scenario "re-uploading the same file does not count anyone twice" do
          sign_in admin
          upload(mixed_csv)
          expect(Attendance.where(event: event).count).to eq(3)
          points_after_first = Point.where(member: [ mennah, trevor, jordan ]).count

          upload(mixed_csv)

          expect(page).to have_content("0 attendance records saved")
          expect(Attendance.where(event: event).count).to eq(3)
          expect(Point.where(member: [ mennah, trevor, jordan ]).count).to eq(points_after_first)
     end

     scenario "AC5: a non-admin cannot open the upload screen" do
          sign_in regular
          visit new_attendance_import_path
          expect(page).to have_current_path(root_path)
     end
end
