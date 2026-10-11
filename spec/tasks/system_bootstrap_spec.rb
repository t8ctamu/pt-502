require "rails_helper"
require "rake"

RSpec.describe "system:bootstrap" do
     before(:all) do
          Rails.application.load_tasks unless Rake::Task.task_defined?("system:bootstrap")
     end

     around do |example|
          values = ENV.to_h.slice("EMAIL", "FIRST_NAME", "LAST_NAME")
          ENV["EMAIL"] = "training-owner@tamu.edu"
          ENV["FIRST_NAME"] = "Training"
          ENV["LAST_NAME"] = "Owner"
          example.run
     ensure
          %w[EMAIL FIRST_NAME LAST_NAME].each { |key| values.key?(key) ? ENV[key] = values[key] : ENV.delete(key) }
     end

     def bootstrap
          Rake::Task["system:bootstrap"].reenable
          Rake::Task["system:bootstrap"].invoke
     end

     it "sets up the initial manager and configuration without duplicating them on retry" do
          expect { bootstrap }.to change(Member, :count).by(1)
          owner = Member.find_by!(email: ENV.fetch("EMAIL"))
          expect(owner).to be_manager
          expect(owner).not_to be_profile_completed
          expect(owner.first_name).to eq("Training")
          expect(Requirement.pluck(:name)).to include("Service", "Professionalism", "Other")
          owner.update!(first_name: "Existing", expected_graduation_term: "Fall 2029")

          expect { bootstrap }.not_to change { [ Member.count, Role.count, Requirement.count, AppSetting.count ] }
          expect(owner.reload.first_name).to eq("Existing")
          expect(owner.expected_graduation_term).to eq("Fall 2029")
     end

     it "rejects a non-TAMU owner before changing data" do
          ENV["EMAIL"] = "owner@example.com"
          expect { bootstrap }.to raise_error(SystemExit)
          expect(Member.find_by(email: ENV["EMAIL"])).to be_nil
     end

     it "does not add a manager when the organization already has another" do
          existing = create(:member, :manager)
          expect { bootstrap }.to raise_error(SystemExit)
          expect(existing.reload).to be_manager
          expect(Member.find_by(email: ENV["EMAIL"])).to be_nil
     end
end
