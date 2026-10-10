require "rails_helper"

RSpec.describe Point, type: :model do
     describe "associations" do
          it "belongs to a member and a requirement" do
               expect(described_class.reflect_on_association(:member).macro).to eq(:belongs_to)
            expect(described_class.reflect_on_association(:requirement).macro).to eq(:belongs_to)
          end
     end

  describe "validations" do
       it "is valid from the factory" do
            expect(build(:point)).to be_valid
       end

    it "requires a member" do
         expect(build(:point, member: nil)).not_to be_valid
    end

    it "requires a requirement" do
         expect(build(:point, requirement: nil)).not_to be_valid
    end

    it "requires an awarded date" do
         expect(build(:point, awarded_date: nil)).not_to be_valid
    end

    [ nil, "abc", 2.5 ].each do |bad|
         it "rejects point_amount #{bad.inspect}" do
              expect(build(:point, point_amount: bad)).not_to be_valid
         end
    end

    it "allows a negative amount so officers can correct mistakes" do
         expect(build(:point, point_amount: -1)).to be_valid
    end
  end

  describe "attendance link" do
       it "nullifies the attendance's point when the point is deleted" do
            point = create(:point)
         attendance = create(:attendance, point: point)

         point.destroy

         expect(attendance.reload.point_id).to be_nil
       end
  end
end
