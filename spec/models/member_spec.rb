require "rails_helper"

RSpec.describe Member, type: :model do
  let!(:service)      { create(:requirement, name: "Service", minimum_points: 3) }
  let!(:professional) { create(:requirement, name: "Professional/Development", minimum_points: 2) }
  let!(:social)       { create(:requirement, name: "Social", minimum_points: 2) }
  let!(:fundraising)  { create(:requirement, name: "Fundraising", minimum_points: 0) }
  let(:member)        { create(:member) }

  def award(requirement, amount, target: member)
    create(:point, member: target, requirement: requirement, point_amount: amount)
    target.reload
  end

  def award_all_minimums
    award(service, 3)
    award(professional, 2)
    award(social, 2)
  end

  describe "profile details" do
    let(:profile) do
      build(:member, expected_graduation_term: "Spring 2027",
                     pt_school_application_date: Date.new(2027, 6, 1))
    end

    it "accepts a graduation term and a summer application cycle" do
      expect(profile.valid?(:profile)).to be true
      expect(profile.anticipated_application_cycle).to eq("Summer 2027")
    end

    it "requires graduation and names when completing a profile" do
      profile.assign_attributes(expected_graduation_term: nil, first_name: "", last_name: "")
      expect(profile.valid?(:profile)).to be false
      expect(profile.errors.attribute_names).to include(:expected_graduation_term, :first_name, :last_name)
    end

    it "rejects an invalid graduation term" do
      profile.expected_graduation_term = "Winter 2027"
      expect(profile.valid?(:profile)).to be false
      expect(profile.errors[:expected_graduation_term]).to be_present
    end

    it "rejects a non-summer application date" do
      profile.pt_school_application_date = Date.new(2027, 1, 1)
      expect(profile.valid?(:profile)).to be false
      expect(profile.errors[:pt_school_application_date].join).to include("Please choose a summer term")
    end

    it "allows an existing member to sign in before completing the new details" do
      profile.expected_graduation_term = nil
      profile.pt_school_application_date = Date.new(2027, 1, 1)
      expect(profile).to be_valid
    end

    it "defaults phone sharing off" do
      expect(profile.share_phone_number?).to be false
      expect(profile.shared_phone_number).to be_nil
    end

    it "discards a phone number supplied without consent" do
      profile.phone_number = "979-555-0123"
      profile.save!(context: :profile)
      expect(profile.reload.phone_number).to be_nil
    end

    it "accepts a formatted phone number with consent" do
      profile.assign_attributes(share_phone_number: true, phone_number: " +1 (979) 555-0123 ")
      profile.save!(context: :profile)
      expect(profile.reload.shared_phone_number).to eq("+1 (979) 555-0123")
    end

    it "rejects missing, short, oversized, or nonnumeric shared phone numbers" do
      [ nil, "123", "1" * 16, "979-555-CALL", "<script>9795550123</script>" ].each do |number|
        profile.assign_attributes(share_phone_number: true, phone_number: number)
        expect(profile.valid?(:profile)).to be false
        expect(profile.errors[:phone_number]).to be_present
      end
    end

    it "removes the saved phone number when consent is withdrawn" do
      profile.assign_attributes(share_phone_number: true, phone_number: "979-555-0123")
      profile.save!(context: :profile)
      profile.update!(share_phone_number: false)
      expect(profile.reload.phone_number).to be_nil
      expect(profile.shared_phone_number).to be_nil
    end

    it "preserves existing contact data during unrelated member edits" do
      profile.save!(context: :profile)
      profile.update_columns(phone_number: "979-555-0123", phone_visible: false)

      profile.update!(paid_dues: true)
      profile.first_name = "Taylor"
      profile.save!(context: :profile)

      expect(profile.reload.phone_number).to eq("979-555-0123")
      expect(profile.shared_phone_number).to be_nil
    end

    it "never exposes an unshared legacy phone number" do
      profile.phone_number = "979-555-0123"
      expect(profile.shared_phone_number).to be_nil
    end
  end

  describe "associations" do
    it "has many point entries without clashing with a points attribute" do
      expect(described_class.reflect_on_association(:point_entries).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:point_entries).class_name).to eq("Point")
    end

    it "destroys attendances and point entries with the member" do
      create(:point, member: member, requirement: service)
      create(:attendance, member: member)

      expect { member.destroy }
        .to change(Point, :count).by(-1)
        .and change(Attendance, :count).by(-1)
    end
  end

  describe "#total_points" do
    it "is 0 with no points" do
      expect(member.total_points).to eq(0)
    end

    it "sums across every type" do
      award(service, 2)
      award(social, 5)
      expect(member.total_points).to eq(7)
    end

    it "subtracts negative corrections" do
      award(service, 3)
      award(service, -1)
      expect(member.total_points).to eq(2)
    end

    it "only counts this member's points" do
      other = create(:member)
      award(service, 4, target: other)
      expect(member.total_points).to eq(0)
    end
  end

  describe "#points_by_requirement" do
    it "is empty with no points" do
      expect(member.points_by_requirement).to eq({})
    end

    it "groups amounts by requirement id" do
      award(service, 1)
      award(service, 2)
      award(social, 4)
      expect(member.points_by_requirement).to eq(service.id => 3, social.id => 4)
    end

    it "is memoized until the member is reloaded" do
      award(service, 1)
      expect(member.points_by_requirement[service.id]).to eq(1)

      create(:point, member: member, requirement: service, point_amount: 5)
      expect(member.points_by_requirement[service.id]).to eq(1) # stale on purpose

      member.reload
      expect(member.points_by_requirement[service.id]).to eq(6)
    end
  end

  describe "#requirement_shortfalls" do
    it "lists every required type for a brand new member" do
      shortfalls = member.requirement_shortfalls.to_h { |s| [ s[:requirement].name, s[:needed] ] }
      expect(shortfalls).to eq("Service" => 3, "Professional/Development" => 2, "Social" => 2)
    end

    it "ignores types with a minimum of 0" do
      names = member.requirement_shortfalls.map { |s| s[:requirement].name }
      expect(names).not_to include("Fundraising")
    end

    it "ignores inactive requirements" do
      service.update!(is_active: false)
      names = member.requirement_shortfalls.map { |s| s[:requirement].name }
      expect(names).not_to include("Service")
    end

    it "reduces the amount needed as points are earned" do
      award(service, 2)
      shortfall = member.requirement_shortfalls.find { |s| s[:requirement] == service }
      expect(shortfall[:needed]).to eq(1)
    end

    it "drops a type once it is met or exceeded" do
      award(service, 10)
      names = member.requirement_shortfalls.map { |s| s[:requirement].name }
      expect(names).not_to include("Service")
    end

    it "is empty when every minimum is met" do
      award_all_minimums
      expect(member.requirement_shortfalls).to be_empty
    end
  end

  describe "#active_status?" do
    it "is false with no points" do
      expect(member).not_to be_active_status
    end

    it "is true when every minimum is met exactly" do
      award_all_minimums
      expect(member).to be_active_status
    end

    it "is true when minimums are exceeded" do
      award_all_minimums
      award(service, 10)
      expect(member).to be_active_status
    end

    it "is FALSE with plenty of total points but one type below its minimum" do
      award(professional, 2)
      award(social, 50)
      expect(member.total_points).to eq(52)
      expect(member).not_to be_active_status
      expect(member.missing_requirements_text).to eq("needs 3 more service points")
    end

    it "is false when a single type is one point short" do
      award(service, 2)
      award(professional, 2)
      award(social, 2)
      expect(member).not_to be_active_status
    end

    it "is true when no requirements are configured" do
      Requirement.update_all(minimum_points: 0)
      expect(member).to be_active_status
    end

    it "points in Fundraising do not satisfy Service" do
      award(fundraising, 30)
      award(professional, 2)
      award(social, 2)
      expect(member).not_to be_active_status
    end

    it "reacts immediately when an officer raises a minimum" do
      award_all_minimums
      expect(member).to be_active_status

      service.update!(minimum_points: 4)
      expect(described_class.find(member.id)).not_to be_active_status
    end

    it "reacts immediately when an officer lowers a minimum" do
      award(service, 2)
      award(professional, 2)
      award(social, 2)
      expect(member).not_to be_active_status

      service.update!(minimum_points: 2)
      expect(described_class.find(member.id)).to be_active_status
    end
  end

  describe "#status_label" do
    it "says Inactive when below a minimum" do
      expect(member.status_label).to eq("Inactive")
    end

    it "says Active when all minimums are met" do
      award_all_minimums
      expect(member.status_label).to eq("Active")
    end
  end

  describe "#missing_requirements_text" do
    it "is blank for an active member" do
      award_all_minimums
      expect(member.missing_requirements_text).to eq("")
    end

    it "names every missing type with plural wording" do
      text = member.missing_requirements_text
      expect(text).to include("needs 3 more service points")
      expect(text).to include("needs 2 more professional/development points")
      expect(text).to include("needs 2 more social points")
    end

    it "uses singular wording when exactly 1 point is missing" do
      award(service, 2)
      award(professional, 2)
      award(social, 2)
      expect(member.missing_requirements_text).to eq("needs 1 more service point")
    end

    it "only mentions the types that are still short" do
      award(service, 3)
      award(professional, 2)
      award(social, 1)
      expect(member.missing_requirements_text).to eq("needs 1 more social point")
    end
  end

  describe "roles" do
    it "delegates admin? to the role" do
      expect(create(:member, :admin)).to be_admin
      expect(create(:member)).not_to be_admin
    end

    it "delegates manager? to the role" do
      expect(create(:member, :manager)).to be_manager
    end
  end

  describe "#profile_completed?" do
    it "is true when profile_completed_at is set" do
      expect(build(:member, :profile_completed)).to be_profile_completed
    end

    it "is false otherwise" do
      expect(build(:member, :incomplete_profile)).not_to be_profile_completed
    end
  end

  describe "validations" do
    it "requires an email" do
      expect(build(:member, email: nil)).not_to be_valid
    end
  end

  describe ".from_google" do
    let(:attrs) do
      { email: "New.Person@tamu.edu ", first_name: "New", last_name: "Person",
        uid: "uid-123", avatar_url: "https://example.com/a.png" }
    end

    it "rejects emails outside tamu.edu" do
      expect(described_class.from_google(**attrs.merge(email: "x@gmail.com"))).to be_nil
    end

    it "creates a member with the Member role and a normalized email" do
      created = described_class.from_google(**attrs)

      expect(created).to be_persisted
      expect(created.email).to eq("new.person@tamu.edu")
      expect(created.role.description).to eq("Member")
      expect(created.joined_at).to eq(Date.current)
    end

    it "updates uid and avatar on an existing member without changing the role" do
      existing = create(:member, :admin, email: "new.person@tamu.edu")
      result = described_class.from_google(**attrs)

      expect(result.id).to eq(existing.id)
      expect(result.uid).to eq("uid-123")
      expect(result).to be_admin
    end

    it "starts a new member with no points and an inactive status" do
      created = described_class.from_google(**attrs)
      expect(created.total_points).to eq(0)
      expect(created).not_to be_active_status
    end
  end
end
