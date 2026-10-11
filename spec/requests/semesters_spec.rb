require "rails_helper"

RSpec.describe "Semesters", type: :request do
     let(:admin) { create(:member, :admin, :profile_completed) }
  let(:regular_member) { create(:member, :profile_completed) }

  describe "GET /semesters" do
       context "when signed out" do
            it "redirects to sign in" do
                 get semesters_path
              expect(response).to redirect_to(new_member_session_path)
            end
       end

    context "when signed in as a regular member" do
         before { sign_in regular_member }

      it "redirects to root with an alert" do
           get semesters_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as an admin" do
         before { sign_in admin }

      it "lists semesters" do
           create(:semester, name: "Fall 2026")
        get semesters_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Fall 2026")
      end
    end
  end

  describe "GET /semesters/:id" do
       let(:semester) { create(:semester) }

    context "when signed in as an admin" do
         before { sign_in admin }

      it "shows the semester details" do
           get semester_path(semester)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(semester.name)
      end
    end
  end

  describe "POST /semesters/reset" do
       context "when signed out" do
            it "redirects to sign in" do
                 post reset_semesters_path
              expect(response).to redirect_to(new_member_session_path)
            end
       end

    context "when signed in as a regular member" do
         before { sign_in regular_member }

      it "redirects to root with an alert" do
           post reset_semesters_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as an admin" do
         before { sign_in admin }

      context "when the current semester is still active" do
           it "refuses to reset" do
                active_semester = create(:semester,
                  starts_on: 1.month.ago, ends_on: 1.month.from_now)
             AppSetting.current.update!(current_semester: active_semester)

             post reset_semesters_path

             expect(response).to redirect_to(members_path)
             expect(flash[:alert]).to include("still active")
             expect(AppSetting.current.reload.current_semester).to eq(active_semester)
           end
      end

      context "when the current semester has ended" do
           it "creates a new semester and sets it as current" do
                ended_semester = create(:semester,
                  name: "Fall 2025",
                  starts_on: 1.year.ago, ends_on: 6.months.ago)
             AppSetting.current.update!(current_semester: ended_semester)

             expect {
                  post reset_semesters_path
             }.to change(Semester, :count).by(1)

             expect(response).to redirect_to(members_path)
             expect(flash[:notice]).to include("Semester reset")
             expect(AppSetting.current.reload.current_semester).not_to eq(ended_semester)
           end

        it "does not modify existing point rows" do
             ended_semester = create(:semester,
               name: "Fall 2025",
               starts_on: 1.year.ago, ends_on: 6.months.ago)
          AppSetting.current.update!(current_semester: ended_semester)

          requirement = create(:requirement, name: "Service")
          member = create(:member, :profile_completed)
          point = create(:point, member: member, requirement: requirement, semester: ended_semester)

          expect {
               post reset_semesters_path
          }.not_to change { point.reload.point_amount }
        end
      end
    end
  end
end
