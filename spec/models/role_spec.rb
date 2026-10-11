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

  describe "#level" do
    it "returns 0 for Member" do
      expect(Role.new(description: "Member").level).to eq(0)
    end

    it "returns 1 for Admin" do
      expect(Role.new(description: "Admin").level).to eq(1)
    end

    it "returns 2 for Manager" do
      expect(Role.new(description: "Manager").level).to eq(2)
    end
    it "returns -1 for an unrecognized description" do
      expect(Role.new(description: "Alumni").level).to eq(-1)
    end
    it "returns 2 for manager (lowercase)" do
      expect(Role.new(description: "manager").level).to eq(2)
    end
    it "returns 1 for ADMIN (uppercase)" do
      expect(Role.new(description: "ADMIN").level).to eq(1)
    end
    it "returns 0 for Member (mixed case)" do
      expect(Role.new(description: "mEmBeR").level).to eq(0)
    end
  end

  describe "#manager?" do
    it "is true for Manager" do
      expect(Role.new(description: "Manager").manager?).to be true
    end

    it "is false for Admin" do
      expect(Role.new(description: "Admin").manager?).to be false
    end

    it "is false for Member" do
      expect(Role.new(description: "Member").manager?).to be false
    end
  end

  describe "#admin?" do
    it "is true for Manager (Manager inherits Admin privileges)" do
      expect(Role.new(description: "Manager").admin?).to be true
    end

    it "is true for Admin" do
      expect(Role.new(description: "Admin").admin?).to be true
    end

    it "is false for Member" do
      expect(Role.new(description: "Member").admin?).to be false
    end
  end
end
