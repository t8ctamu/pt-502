require "rails_helper"

RSpec.describe "AttendanceImports", type: :request do
     let(:admin) { create(:member, :admin, :profile_completed) }
     let(:regular) { create(:member, :profile_completed) }
     let(:requirement) { create(:requirement, name: "Service") }
     let!(:event) do
          create(:event, :check_in_ready, latitude: 30.6, longitude: -96.3,
                 point_value: 2, requirement: requirement)
     end

     let!(:member_one) { create(:member, :profile_completed, email: "ktmd3368@email.tamu.edu") }
     let!(:member_two) { create(:member, :profile_completed, email: "trevorpatton249@email.tamu.edu") }
     let!(:member_three) { create(:member, :profile_completed, email: "jordanlee@email.tamu.edu") }

     def upload(path, mime: "text/csv")
          Rack::Test::UploadedFile.new(Rails.root.join(path), mime)
     end

     describe "GET /attendance_imports/new" do
          it "redirects signed-out users" do
               get new_attendance_import_path
               expect(response).to redirect_to(new_member_session_path)
          end

          it "redirects regular members" do
               sign_in regular
               get new_attendance_import_path
               expect(response).to redirect_to(root_path)
          end

          it "renders for admins with an event picker" do
               sign_in admin
               get new_attendance_import_path
               expect(response).to have_http_status(:ok)
               expect(response.body).to include("Import attendance", event.name)
          end

          it "filters events by name search" do
               sign_in admin
               get new_attendance_import_path, params: { q: event.name }
               expect(response.body).to include(event.name)
          end
     end

     describe "GET /attendance_imports/:event_id/upload" do
          it "shows the upload form scoped to the event" do
               sign_in admin
               get upload_attendance_import_path(event.id)
               expect(response).to have_http_status(:ok)
               expect(response.body).to include(event.name, "Attendance file")
          end
     end

     describe "POST /attendance_imports" do
          before { sign_in admin }

          it "rejects a file with the wrong extension and saves nothing" do
               bad = Rack::Test::UploadedFile.new(
                    Rails.root.join("spec/fixtures/files/attendance_uat_mixed.csv"),
                    "text/plain",
                    original_filename: "attendance.txt"
               )

               expect do
                    post attendance_imports_path, params: { event_id: event.id, file: bad }
               end.not_to change { Attendance.count }

               expect(response).to have_http_status(:unprocessable_content)
               expect(response.body).to include("Please upload")
          end

          it "rejects a file missing required columns and saves nothing" do
               expect do
                    post attendance_imports_path, params: {
                         event_id: event.id,
                         file: upload("spec/fixtures/files/attendance_uat_missing_columns.csv")
                    }
               end.not_to change { Attendance.count }

               expect(response).to have_http_status(:unprocessable_content)
               expect(response.body).to include("missing required column")
          end

          it "imports valid rows, reports row errors, and redirects to results" do
               post attendance_imports_path, params: {
                    event_id: event.id,
                    file: upload("spec/fixtures/files/attendance_uat_mixed.csv")
               }

               expect(response).to redirect_to(results_attendance_imports_path)
               follow_redirect!

               expect(response.body).to include("3 attendance records saved")
               expect(response.body).to include("ghost@email.tamu.edu")
               expect(Attendance.where(event: event).count).to eq(3)
               expect(Point.where(member: member_one).count).to eq(1)
          end

          it "shows a message when there is no recent import to display" do
               get results_attendance_imports_path
               expect(response).to redirect_to(new_attendance_import_path)
          end
     end
end
