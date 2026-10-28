# spec/requests/point_settings_types_spec.rb
require "rails_helper"

RSpec.describe "Point type deletion", type: :request do
     let(:manager) { create(:member, :profile_completed, :manager) }
  before { sign_in manager }

  it "refuses to delete core types" do
       core = create(:requirement, name: "Service")
    delete destroy_type_point_settings_path(core)   # check `rails routes` for the helper
    expect(flash[:alert]).to include("core type")
    expect(Requirement.exists?(core.id)).to be(true)
  end

  it "deletes an unused custom type" do
       custom = create(:requirement, name: "Fundraising")
    expect { delete destroy_type_point_settings_path(custom) }.to change(Requirement, :count).by(-1)
    expect(flash[:notice]).to include("Deleted point type")
  end

  it "explains when a type is in use" do
       custom = create(:requirement, name: "Fundraising")
    create(:point, requirement: custom)
    delete destroy_type_point_settings_path(custom)
    expect(flash[:alert]).to include("in use")
  end

  it "updates the total points required" do
       patch point_settings_path, params: { total_points_required: "7" }
    expect(AppSetting.current.total_points_required).to eq(7)
  end

  it "shows the add-type error page" do
       post add_type_point_settings_path, params: { name: "" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(flash[:alert]).to eq("Could not add the point type.")
  end
end
