require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates the default point types with their minimums" do
    run_seeds

    minimums = Requirement.pluck(:name, :minimum_points).to_h
    expect(minimums).to include("Service" => 1, "Professionalism" => 1, "Other" => 0)
    expect(minimums.keys).to match_array(%w[Service Professionalism Other])
  end

  it "includes a service type and a professional/development type" do
    run_seeds
    expect(Requirement.where(name: ["Service", "Professionalism"]).count).to eq(2)
  end

  it "is safe to run twice" do
    run_seeds
    expect { run_seeds }.not_to change(Requirement, :count)
  end

  it "does not overwrite minimums an officer already changed" do
    run_seeds
    Requirement.find_by!(name: "Service").update!(minimum_points: 8)
    run_seeds
    expect(Requirement.find_by!(name: "Service").minimum_points).to eq(8)
  end

  it "creates the Admin, Manager and Member roles" do
    run_seeds
    expect(Role.pluck(:description)).to include("Admin", "Manager", "Member")
  end
end
