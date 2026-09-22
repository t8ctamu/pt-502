require "rails_helper"

RSpec.describe Role, type: :model do
  it "can be created with a description" do
    role = create(:role, :admin)
    expect(role).to be_persisted
    expect(role.description).to eq("Admin")
  end

  it "does not create duplicate roles with the same description" do
    create(:role, description: "Officer")

    expect {
      Role.find_or_create_by(description: "Officer")
    }.not_to change(Role, :count)
  end
end