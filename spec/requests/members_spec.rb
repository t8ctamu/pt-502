require "rails_helper"

RSpec.describe "Members", type: :request do
  let(:admin) { create(:member, :admin, :profile_completed) }
  let(:regular_member) { create(:member, :profile_completed) }

  describe "GET /members" do
    context "when signed out" do
      it "redirects to sign in" do
        get members_path
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context "when signed in as a non-admin member" do
      before { sign_in regular_member }

      it "redirects to root with an alert" do
        get members_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when the signed-in admin's own profile is incomplete" do
      before { sign_in create(:member, :admin) }

      it "redirects to the profile edit form first" do
        get members_path
        expect(response).to redirect_to(edit_profile_path)
      end
    end

    context "when signed in as an admin with a completed profile" do
      before { sign_in admin }

      it "returns a successful response and lists members" do
        create(:member, :profile_completed, first_name: "Alex")

        get members_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Alex")
      end
    end
  end

  describe "PATCH /members/:id" do
    before { sign_in admin }

    it "does not change points through the dues update endpoint" do
      target = create(:member, :profile_completed, points: 5)
      patch member_path(target), params: { member: { paid_dues: true, points: 999 } }
      expect(target.reload.points).to eq(5)
    end

    it "updates the member's paid_dues status and redirects to the index" do
      target = create(:member, :profile_completed, paid_dues: false)

      patch member_path(target), params: { member: { paid_dues: true } }

      expect(response).to redirect_to(members_path)
      expect(target.reload.paid_dues).to be true
    end
  end

  describe "PATCH /members/:id/change_role" do
    let(:manager) { create(:member, :manager, :profile_completed) }
    let(:target) { create(:member, :profile_completed) }

    context "when signed out" do
      it "redirects to sign in" do
        patch change_role_member_path(target), params: { role: "Admin" }
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context "when signed in as a regular member" do
      before { sign_in regular_member }

      it "redirects to root with an alert and does not change the target role" do
        patch change_role_member_path(target), params: { role: "Admin" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You're not authorized to change roles.")
        expect(target.reload.role.description).to eq("Member")
      end
    end

    context "when signed in as an admin" do
      before { sign_in admin }

      it "redirects to root with an alert and does not change the target role" do
        patch change_role_member_path(target), params: { role: "Admin" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You're not authorized to change roles.")
        expect(target.reload.role.description).to eq("Member")
      end
    end

    context "when signed in as a manager" do
      let(:manager) { create(:member, :manager, :profile_completed) }

      before { sign_in manager }

      it "shows admins in a separate table and excludes them from the members table" do
        create(:member, :admin,  :profile_completed, first_name: "Ada")
        create(:member,          :profile_completed, first_name: "Bob")

        get members_path

        expect(response.body).to include("Admins")
        expect(response.body).to include("Ada")
        expect(response.body).to include("Bob")

        # Ada's name appears exactly once — in the admins table, not duplicated
        expect(response.body.scan("Ada").size).to eq(1)
      end

      it "moves a member between tables when their role changes" do
        promoted = create(:member, :profile_completed, first_name: "Carol")
        get members_path
        expect(response.body).to include("Carol")

        promoted.update!(role: Role.find_by!(description: "Admin"))

        get members_path
        expect(response.body.scan("Carol").size).to eq(1)
        expect(response.body.index("Carol")).to be > response.body.index("Admins")
      end

      it "shows 'No admins to display' when there are no admins" do
        Member.admins.update_all(role_id: Role.find_by!(description: "Member").id)

        get members_path

        expect(response.body).to include("No admins to display")
      end

      it "hides phone numbers for admins who haven't opted in" do
        create(:member, :admin, :profile_completed,
              phone_number: "555-1234", phone_visible: false)

        get members_path

        expect(response.body).not_to include("555-1234")
      end

      it "shows phone numbers for admins who opted in" do
        create(:member, :admin, :profile_completed,
              phone_number: "555-1234", phone_visible: true)

        get members_path

        expect(response.body).to include("555-1234")
      end

      it "renders members table with a clear message when admins fail to load" do
        create(:member, :admin,  :profile_completed, first_name: "Ada")
        create(:member,          :profile_completed, first_name: "Bob")

        allow(Member).to receive(:admins).and_raise(StandardError, "boom")

        get members_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Bob")
        expect(response.body).to include("Admins could not be loaded")
      end
    end

    context "when signed in as an admin (not a manager)" do
      before { sign_in admin }

      it "shows the admins table" do
        create(:member, :admin, :profile_completed, first_name: "Ada")

        get members_path

        expect(response.body).to include("Admins")
        expect(response.body).to include("Ada")
      end
    end

    context "when signed in as a manager" do
      before { sign_in manager }

      it "promotes a member to admin" do
        patch change_role_member_path(target), params: { role: "Admin" }
        expect(response).to redirect_to(members_path)
        expect(flash[:notice]).to eq("#{target.first_name} is now Admin.")
        expect(target.reload.role.description).to eq("Admin")
      end

      it "demotes an admin to member" do
        admin_target = create(:member, :admin, :profile_completed)

        patch change_role_member_path(admin_target), params: { role: "Member" }

        expect(response).to redirect_to(members_path)
        expect(admin_target.reload.role.description).to eq("Member")
      end

      it "refuses to change their own role" do
        patch change_role_member_path(manager), params: { role: "Member" }
        expect(response).to redirect_to(members_path)
        expect(flash[:alert]).to eq("You cannot change your own role.")
        expect(manager.reload.role.description).to eq("Manager")
      end

      it "refuses to change another manager's role" do
        other_manager = create(:member, :manager, :profile_completed)

        patch change_role_member_path(other_manager), params: { role: "Member" }

        expect(response).to redirect_to(members_path)
        expect(flash[:alert]).to eq("You cannot change a Manager's role.")
        expect(other_manager.reload.role.description).to eq("Manager")
      end

      it "refuses to promote to Manager" do
        patch change_role_member_path(target), params: { role: "Manager" }
        expect(response).to redirect_to(members_path)
        expect(flash[:alert]).to eq("Invalid role change.")
        expect(target.reload.role.description).to eq("Member")
      end

      it "refuses an unknown role" do
        patch change_role_member_path(target), params: { role: "Alumni" }
        expect(response).to redirect_to(members_path)
        expect(flash[:alert]).to eq("Invalid role change.")
        expect(target.reload.role.description).to eq("Member")
      end

      it "refuses a nil role" do
        patch change_role_member_path(target), params: { role: nil }
        expect(response).to redirect_to(members_path)
        expect(flash[:alert]).to eq("Invalid role change.")
        expect(target.reload.role.description).to eq("Member")
      end
    end
  end
end
