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

      it "shows graduation, summer cycle, carpool availability, and opted-in phone numbers" do
        create(:member, :profile_completed, first_name: "Carpooler", car_pool_status: true,
               expected_graduation_term: "Fall 2028", pt_school_application_date: Date.new(2027, 6, 1),
               share_phone_number: true, phone_number: "979-555-0134")
        hidden = create(:member, :profile_completed)
        hidden.update_columns(phone_number: "979-555-0199", share_phone_number: false)
        get members_path
        expect(response.body).to include("Carpooler", "Fall 2028", "Summer 2027", "979-555-0134", "Not shared")
        expect(response.body).not_to include("979-555-0199")
      end
    end
  end

  describe "GET /members/:id/edit" do
    it "requires sign in" do
      get edit_member_path(regular_member)
      expect(response).to redirect_to(new_member_session_path)
    end

    it "does not allow regular members to edit another member" do
      sign_in regular_member
      get edit_member_path(admin)
      expect(response).to redirect_to(root_path)
    end

    it "allows officers to edit details without phone consent controls" do
      sign_in admin
      get edit_member_path(regular_member)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Expected graduation", "Anticipated application cycle")
      expect(response.body).not_to include('name="member[share_phone_number]"', 'name="member[phone_number]"')
    end
  end

  describe "PATCH /members/:id" do
    before { sign_in admin }

    it "does not change points through the dues update endpoint" do
      requirement = create(:requirement, name: "Service")
      target = create(:member, :profile_completed)
      create(:point, member: target, requirement: requirement, point_amount: 5)

      patch member_path(target), params: { member: { paid_dues: "1", points: 99 } }

      expect(target.reload.total_points).to eq(5)
      expect(Point.where(member: target).count).to eq(1)
    end

    it "updates the member's paid_dues status and redirects to the index" do
      target = create(:member, :profile_completed, paid_dues: false)

      patch member_path(target), params: { member: { paid_dues: true } }

      expect(response).to redirect_to(members_path)
      expect(target.reload.paid_dues).to be true
    end

    it "allows officers to update profile details but never phone consent, points, or roles" do
      target = create(:member, :profile_completed, share_phone_number: true, phone_number: "979-555-0123")
      original_role = target.role_id
      patch member_path(target), params: { member: {
        expected_graduation_term: "Fall 2029", pt_school_application_date: "2028-06-01", car_pool_status: "1",
        phone_number: "979-555-0199", share_phone_number: "0", phone_visible: "0", points: 999, role_id: admin.role_id
      } }
      expect(response).to redirect_to(members_path)
      target.reload
      expect(target.expected_graduation_term).to eq("Fall 2029")
      expect(target.anticipated_application_cycle).to eq("Summer 2028")
      expect(target.car_pool_status?).to be true
      expect(target.shared_phone_number).to eq("979-555-0123")
      expect(target.role_id).to eq(original_role)
      expect(target.total_points).to eq(0)
    end

    it "does not allow an officer to opt a member into phone sharing" do
      target = create(:member, :profile_completed)
      patch member_path(target), params: { member: { expected_graduation_term: "Fall 2029", share_phone_number: "1", phone_number: "979-555-0123" } }
      expect(target.reload.share_phone_number?).to be false
      expect(target.phone_number).to be_nil
    end

    it "preserves existing details and explains an invalid officer edit" do
      target = create(:member, :profile_completed)
      original = target.attributes
      patch member_path(target), params: { member: { expected_graduation_term: "", pt_school_application_date: "2028-01-01" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Please correct your profile", "Please choose a summer term")
      expect(target.reload.attributes).to eq(original)
    end

    it "blocks unauthorized profile updates" do
      sign_out admin
      sign_in regular_member
      patch member_path(admin), params: { member: { expected_graduation_term: "Fall 2030" } }
      expect(response).to redirect_to(root_path)
      expect(admin.reload.expected_graduation_term).not_to eq("Fall 2030")
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
        expect(flash[:alert]).to eq("Access denied: managers only")
        expect(target.reload.role.description).to eq("Member")
      end
    end

    context "when signed in as an admin" do
      before { sign_in admin }

      it "redirects to root with an alert and does not change the target role" do
        patch change_role_member_path(target), params: { role: "Admin" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied: managers only")
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
        expect(Nokogiri::HTML(response.body).text.scan("Ada").size).to eq(1)
      end

      it "moves a member between tables when their role changes" do
        promoted = create(:member, :profile_completed, first_name: "Carol")
        get members_path
        expect(response.body).to include("Carol")

        promoted.update!(role: Role.find_by!(description: "Admin"))

        get members_path
        expect(Nokogiri::HTML(response.body).text.scan("Carol").size).to eq(1)
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

      describe "PATCH /members/:id/remove" do
    let(:target)  { create(:member, :profile_completed) }
    let(:manager) { create(:member, :profile_completed, :manager) }

    context "when signed out" do
      it "redirects to sign in" do
        patch remove_member_path(target)
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context "when signed in as a regular member" do
      before { sign_in regular_member }

      it "redirects to root with an alert and does not remove the member" do
        patch remove_member_path(target)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied: managers only")
        expect(target.reload.removed_at).to be_nil
      end
    end

    context "when signed in as an admin (officer)" do
      before { sign_in admin }

      it "is blocked and does not remove the member" do
        patch remove_member_path(target)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied: managers only")
        expect(target.reload.removed_at).to be_nil
      end
    end

    context "when signed in as a manager" do
      before { sign_in manager }

      it "sets removed_at and redirects with a notice" do
        patch remove_member_path(target)
        expect(response).to redirect_to(members_path)
        expect(flash[:notice]).to include("#{target.first_name} removed")
        expect(target.reload.removed_at).not_to be_nil
      end

      it "refuses to remove self" do
        patch remove_member_path(manager)
        expect(response).to redirect_to(members_path)
        expect(flash[:alert]).to eq("You cannot remove yourself.")
        expect(manager.reload.removed_at).to be_nil
      end

      it "refuses to remove another manager" do
        other = create(:member, :manager, :profile_completed)

        patch remove_member_path(other)

        expect(response).to redirect_to(members_path)
        expect(flash[:alert]).to eq("You cannot remove a Manager.")
        expect(other.reload.removed_at).to be_nil
      end
    end
  end

  describe "PATCH /members/:id/restore" do
    let(:removed_member) { create(:member, :profile_completed, removed_at: 2.days.ago) }
    let(:manager)        { create(:member, :profile_completed, :manager) }

    context "when signed out" do
      it "redirects to sign in" do
        patch restore_member_path(removed_member)
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context "when signed in as a regular member" do
      before { sign_in regular_member }

      it "redirects to root with an alert and does not restore the member" do
        patch restore_member_path(removed_member)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied: managers only")
        expect(removed_member.reload.removed_at).not_to be_nil
      end
    end

    context "when signed in as an admin (officer)" do
      before { sign_in admin }

      it "is blocked and does not restore the member" do
        patch restore_member_path(removed_member)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied: managers only")
        expect(removed_member.reload.removed_at).not_to be_nil
      end
    end

    context "when signed in as a manager" do
      before { sign_in manager }

      it "clears removed_at and redirects with a notice" do
        patch restore_member_path(removed_member)
        expect(response).to redirect_to(members_path)
        expect(flash[:notice]).to include("#{removed_member.first_name} restored")
        expect(removed_member.reload.removed_at).to be_nil
      end
    end
  end
end
