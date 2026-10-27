# spec/requests/members_roles_spec.rb
require "rails_helper"

RSpec.describe "Member removal and role changes", type: :request do
     let(:manager) { create(:member, :profile_completed, :manager) }
  let(:officer) { create(:member, :profile_completed, :admin) }
  let!(:target) { create(:member, :profile_completed) }
  let(:blocked) { "Access denied: managers only" }

  context "as an officer" do
       before { sign_in officer }

    it "can still view the dashboard" do
         get members_path
      expect(response).to have_http_status(:ok)
    end

    it "does not show remove or promote controls" do
         get members_path
      expect(response.body).not_to include("Remove")
      expect(response.body).not_to include("Promote")
    end

    it "blocks removal and changes nothing" do
         patch remove_member_path(target)
      expect(flash[:alert]).to eq(blocked)
      expect(target.reload.removed_at).to be_nil
    end

    it "blocks restore" do
         target.update!(removed_at: Time.current)
      patch restore_member_path(target)
      expect(flash[:alert]).to eq(blocked)
      expect(target.reload.removed_at).to be_present
    end

    it "blocks role changes" do
         expect { patch change_role_member_path(target), params: { role: "admin" } }
           .not_to change { target.reload.role_id }
      expect(flash[:alert]).to eq(blocked)
    end
  end

  context "as a regular member" do
       it "is blocked from removing and changing roles" do
            sign_in create(:member, :profile_completed)
         patch remove_member_path(target)
         patch change_role_member_path(target), params: { role: "admin" }
         expect(target.reload.removed_at).to be_nil
         expect(target.role.description).to eq("Member")
       end
  end

  context "as a manager" do
       before { sign_in manager }

    it "removes and restores a member" do
         patch remove_member_path(target)
      expect(flash[:notice]).to include("removed from the roster")
      expect(target.reload.removed_at).to be_present

      patch restore_member_path(target)
      expect(flash[:notice]).to include("restored to the roster")
      expect(target.reload.removed_at).to be_nil
    end

    it "promotes and demotes" do
         patch change_role_member_path(target), params: { role: "Admin" }
      expect(target.reload).to be_admin
      patch change_role_member_path(target), params: { role: "member" }
      expect(target.reload).not_to be_admin
    end

    it "refuses to remove or re-role themselves" do
         patch remove_member_path(manager)
      expect(flash[:alert]).to eq("You cannot remove yourself.")
      patch change_role_member_path(manager), params: { role: "member" }
      expect(flash[:alert]).to eq("You cannot change your own role.")
    end

    it "refuses to touch another manager" do
         other = create(:member, :profile_completed, :manager)
      patch remove_member_path(other)
      expect(flash[:alert]).to eq("You cannot remove a Manager.")
      patch change_role_member_path(other), params: { role: "member" }
      expect(flash[:alert]).to eq("You cannot change a Manager's role.")
    end

    it "rejects invalid or manager role targets" do
         patch change_role_member_path(target), params: { role: "Manager" }
      expect(flash[:alert]).to eq("Invalid role change.")
      patch change_role_member_path(target), params: { role: "nonsense" }
      expect(flash[:alert]).to eq("Invalid role change.")
    end

    it "reports a failed update" do
         allow_any_instance_of(Member).to receive(:update).and_return(false)
      patch remove_member_path(target)
      expect(flash[:alert]).to eq("Could not remove #{target.first_name}.")
      patch restore_member_path(target)
      expect(flash[:alert]).to eq("Could not restore #{target.first_name}.")
      patch change_role_member_path(target), params: { role: "admin" }
      expect(flash[:alert]).to eq("Could not change #{target.first_name}'s role.")
    end
  end

  describe "set_points and edit/update" do
       let!(:service) { create(:requirement, name: "Service", minimum_points: 3) }
    before { sign_in officer }

    it "sets a type total by adding a correcting entry" do
         patch set_points_member_path(target), params: { requirement_id: service.id, total: "5" }
      expect(target.reload.points_by_requirement[service.id]).to eq(5)
      patch set_points_member_path(target), params: { requirement_id: service.id, total: "2" }
      expect(target.reload.points_by_requirement[service.id]).to eq(2)
    end

    it "does nothing when the total is unchanged" do
         expect { patch set_points_member_path(target), params: { requirement_id: service.id, total: "0" } }
           .not_to change(Point, :count)
    end

    it "rejects bad totals and unknown types" do
         [ "abc", "-1", "" ].each do |bad|
              patch set_points_member_path(target), params: { requirement_id: service.id, total: bad }
           expect(flash[:alert]).to eq("Enter a whole number of 0 or more.")
         end
      patch set_points_member_path(target), params: { requirement_id: 0, total: "1" }
      expect(flash[:alert]).to eq("Enter a whole number of 0 or more.")
    end

    it "shows the edit page" do
         get edit_member_path(target)
      expect(response).to have_http_status(:ok)
    end

    it "updates a profile" do
         patch member_path(target), params: { member: { first_name: "Newname", last_name: "Person" } }
      expect(target.reload.first_name).to eq("Newname")
      expect(flash[:notice]).to include("profile updated")
    end

    it "re-renders the edit form on an invalid profile" do
         patch member_path(target), params: { member: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
