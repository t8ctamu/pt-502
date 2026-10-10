require "rails_helper"

RSpec.describe Requirement, type: :model do
     describe "defaults" do
          it "starts with a minimum of 0 and active" do
               requirement = described_class.new
            expect(requirement.minimum_points).to eq(0)
            expect(requirement.is_active).to be(true)
          end
     end

  describe "associations" do
       it "has many events" do
            expect(described_class.reflect_on_association(:events).macro).to eq(:has_many)
       end

    it "has many points" do
         expect(described_class.reflect_on_association(:points).macro).to eq(:has_many)
    end
  end

  describe "validations" do
       it "is valid with a name and minimum" do
            expect(build(:requirement, name: "Service", minimum_points: 3)).to be_valid
       end

    it "requires a name" do
         requirement = build(:requirement, name: "")
      expect(requirement).not_to be_valid
      expect(requirement.errors[:name]).to be_present
    end

    it "rejects duplicate names regardless of case" do
         create(:requirement, name: "Service")
      duplicate = build(:requirement, name: "service")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    describe "minimum_points" do
         [ 0, "0", 1, "4", 100 ].each do |good|
              it "accepts #{good.inspect}" do
                   expect(build(:requirement, minimum_points: good)).to be_valid
              end
         end

      [ "", " ", nil, "-1", -1, "abc", "2.5", 2.5, "1,000" ].each do |bad|
           it "rejects #{bad.inspect} with a clear message" do
                requirement = build(:requirement, minimum_points: bad)
             expect(requirement).not_to be_valid
             expect(requirement.errors[:minimum_points]).to include("Enter a whole number of 0 or more")
           end
      end
    end
  end

  describe ".active" do
       it "returns only active requirements" do
            active = create(:requirement)
         create(:requirement, :inactive)
         expect(described_class.active).to contain_exactly(active)
       end
  end

  describe "deletion safety" do
       it "cannot be destroyed while events use it" do
            requirement = create(:requirement)
         create(:event, requirement: requirement)

         expect(requirement.destroy).to be(false)
         expect(requirement.errors[:base]).to be_present
         expect(described_class.exists?(requirement.id)).to be(true)
       end

    it "cannot be destroyed while points reference it" do
         requirement = create(:requirement)
      create(:point, requirement: requirement)

      expect(requirement.destroy).to be(false)
      expect(described_class.exists?(requirement.id)).to be(true)
    end

    it "can be destroyed when unused" do
         requirement = create(:requirement)
      expect { requirement.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe "database constraints" do
       it "refuses a negative minimum even if validations are skipped" do
            requirement = build(:requirement, minimum_points: -5)
         expect { requirement.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
       end
  end
end
