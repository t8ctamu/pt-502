require "rails_helper"

RSpec.describe "Point settings", type: :request do
     include Devise::Test::IntegrationHelpers

  let(:manager)  { create(:member, :profile_completed, :manager) }
  let(:member) { create(:member, :profile_completed) }

  let!(:service)      { create(:requirement, name: "Service", minimum_points: 3) }
  let!(:professional) { create(:requirement, name: "Professional/Development", minimum_points: 2) }
  let!(:social)       { create(:requirement, name: "Social", minimum_points: 2) }

  ERROR_TEXT = "Enter a whole number of 0 or more".freeze
  SAVE_FAILED_TEXT = "Changes could not be saved, try again or contact an admin.".freeze

  def settings_params(service: "3", professional: "2", social: "2")
       {
         requirements: {
           self.service.id.to_s      => { minimum_points: service },
           self.professional.id.to_s => { minimum_points: professional },
           self.social.id.to_s       => { minimum_points: social }
         }
       }
  end

  def minimums
       Requirement.order(:name).pluck(:name, :minimum_points).to_h
  end

  let(:original_minimums) { { "Professional/Development" => 2, "Service" => 3, "Social" => 2 } }

  describe "GET /point_settings" do
       it "shows every point type and its minimum to an officer" do
            sign_in manager
         get point_settings_path

         expect(response).to have_http_status(:ok)
         expect(response.body).to include("Service", "Professional/Development", "Social")
         expect(response.body).to include(%(value="3"))
         expect(response.body).to include("Save requirements")
       end

    it "includes inactive types so officers can reactivate or review them" do
         create(:requirement, :inactive, name: "Retired")
      sign_in manager
      get point_settings_path
      expect(response.body).to include("Retired")
    end

    it "redirects a regular member with an Admins only message" do
         sign_in member
      get point_settings_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Managers only.")
    end

    it "does not show settings to a signed-out visitor" do
         get point_settings_path
      expect(response).to have_http_status(:redirect)
      expect(response).not_to have_http_status(:ok)
    end

    it "does not show settings to an officer with an incomplete profile" do
         sign_in create(:member, :profile_completed, :manager, :incomplete_profile)
      get point_settings_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /point_settings (sunny day)" do
       before { sign_in manager }

    it "saves new minimums for every type" do
         patch point_settings_path, params: settings_params(service: "5", professional: "1", social: "4")

      expect(response).to redirect_to(point_settings_path)
      expect(flash[:notice]).to eq("Point requirements saved.")
      expect(minimums).to eq("Professional/Development" => 1, "Service" => 5, "Social" => 4)
    end

    it "saves the example from the user story: 3 service, 2 development, 2 social" do
         Requirement.update_all(minimum_points: 0)
      patch point_settings_path, params: settings_params(service: "3", professional: "2", social: "2")

      expect(minimums).to eq(original_minimums)
    end

    it "allows 0, meaning not required" do
         patch point_settings_path, params: settings_params(social: "0")
      expect(social.reload.minimum_points).to eq(0)
    end

    it "only changes the types that were submitted" do
         patch point_settings_path, params: {
           requirements: { service.id.to_s => { minimum_points: "9" } }
         }

      expect(service.reload.minimum_points).to eq(9)
      expect(professional.reload.minimum_points).to eq(2)
      expect(social.reload.minimum_points).to eq(2)
    end

    it "ignores ids that do not exist" do
         patch point_settings_path, params: {
           requirements: { "999999" => { minimum_points: "9" } }
         }
      expect(response).to redirect_to(point_settings_path)
      expect(minimums).to eq(original_minimums)
    end

    it "changes member status as soon as minimums change" do
         target = create(:member, :profile_completed)
      create(:point, member: target, requirement: service, point_amount: 3)
      create(:point, member: target, requirement: professional, point_amount: 2)
      create(:point, member: target, requirement: social, point_amount: 2)
      expect(Member.find(target.id)).to be_active_status

      patch point_settings_path, params: settings_params(service: "4")

      fresh = Member.find(target.id)
      expect(fresh).not_to be_active_status
      expect(fresh.missing_requirements_text).to eq("needs 1 more service point")
    end
  end

  describe "PATCH /point_settings (invalid input)" do
       before { sign_in manager }

    [ "", " ", "-1", "abc", "2.5", "1,000", "-0.5" ].each do |bad|
         it "rejects #{bad.inspect}, shows a clear error and keeps the old values" do
              patch point_settings_path, params: settings_params(service: bad)

           expect(response).to have_http_status(:unprocessable_content)
           expect(response.body).to include(ERROR_TEXT)
           expect(response.body).to include("No changes were saved.")
           expect(minimums).to eq(original_minimums)
         end
    end

    it "redisplays what the officer typed" do
         patch point_settings_path, params: settings_params(service: "abc")
      expect(response.body).to include(%(value="abc"))
    end

    it "shows the error next to only the bad field" do
         patch point_settings_path, params: settings_params(social: "-3")
      expect(response.body.scan(ERROR_TEXT).size).to eq(1)
    end

    it "shows an error for each bad field" do
         patch point_settings_path, params: settings_params(service: "x", social: "y")
      expect(response.body.scan(ERROR_TEXT).size).to eq(2)
    end

    it "saves nothing at all when one field is bad and the others are fine" do
         patch point_settings_path, params: settings_params(service: "9", professional: "8", social: "abc")

      expect(response).to have_http_status(:unprocessable_content)
      expect(minimums).to eq(original_minimums)
    end

    it "leaves existing member statuses untouched after a rejected save" do
         target = create(:member, :profile_completed)
      create(:point, member: target, requirement: service, point_amount: 3)
      create(:point, member: target, requirement: professional, point_amount: 2)
      create(:point, member: target, requirement: social, point_amount: 2)

      patch point_settings_path, params: settings_params(service: "99", social: "abc")

      expect(Member.find(target.id)).to be_active_status
    end
  end

  describe "PATCH /point_settings (system failure)" do
       before { sign_in manager }

    it "shows a clear message, saves nothing and does not fail silently" do
         allow_any_instance_of(Requirement).to receive(:save!)
           .and_raise(ActiveRecord::StatementInvalid.new("db down"))

      patch point_settings_path, params: settings_params(service: "7")

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("Changes could not be saved, try again or contact an admin.")
      expect(minimums).to eq(original_minimums)
    end

    it "logs the failure" do
         allow_any_instance_of(Requirement).to receive(:save!).and_raise(StandardError, "kaboom")
      allow(Rails.logger).to receive(:error)

      patch point_settings_path, params: settings_params(service: "7")

      expect(Rails.logger).to have_received(:error).with(/Point settings save failed/)
    end
  end

  describe "PATCH /point_settings (unauthorized)" do
       it "blocks a regular member and changes nothing" do
            sign_in member
         patch point_settings_path, params: settings_params(service: "0", professional: "0", social: "0")

         expect(response).to redirect_to(root_path)
         expect(flash[:alert]).to eq("Managers only.")
         expect(minimums).to eq(original_minimums)
       end

    it "blocks a signed-out visitor and changes nothing" do
         patch point_settings_path, params: settings_params(service: "0")

      expect(response).to have_http_status(:redirect)
      expect(minimums).to eq(original_minimums)
    end

    it "blocks an officer whose profile is incomplete" do
         sign_in create(:member, :profile_completed, :manager, :incomplete_profile)
      patch point_settings_path, params: settings_params(service: "0")

      expect(minimums).to eq(original_minimums)
    end
  end

  describe "POST /point_settings/add_type" do
       let(:manager) do
            create(:member, role: Role.find_or_create_by!(description: "Manager"),
                            profile_completed_at: Time.current)
       end

    before { sign_in manager }

    it "adds a new point type with its minimum" do
         expect {
              post add_type_point_settings_path, params: { name: "Fundraising", minimum_points: "2" }
         }.to change(Requirement, :count).by(1)

      expect(response).to redirect_to(point_settings_path)
      expect(Requirement.find_by(name: "Fundraising").minimum_points).to eq(2)
    end

    it "defaults the minimum to 0 when left blank" do
         post add_type_point_settings_path, params: { name: "Fundraising", minimum_points: "" }
      expect(Requirement.find_by(name: "Fundraising").minimum_points).to eq(0)
    end

    it "rejects a blank name" do
         expect {
              post add_type_point_settings_path, params: { name: " ", minimum_points: "1" }
         }.not_to change(Requirement, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a duplicate name regardless of case" do
         Requirement.find_or_create_by!(name: "Service") { |r| r.minimum_points = 1 }
      expect {
           post add_type_point_settings_path, params: { name: "service", minimum_points: "1" }
      }.not_to change(Requirement, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects an invalid minimum" do
         expect {
              post add_type_point_settings_path, params: { name: "Social", minimum_points: "abc" }
         }.not_to change(Requirement, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "blocks an admin who is not a manager" do
         admin = create(:member, role: Role.find_or_create_by!(description: "Admin"),
                                 profile_completed_at: Time.current)
      sign_in admin
      expect {
           post add_type_point_settings_path, params: { name: "Social", minimum_points: "1" }
      }.not_to change(Requirement, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
