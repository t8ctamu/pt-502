require "rails_helper"

RSpec.describe Member, type: :model do
  describe "validations" do
    it "requires an email" do
      member = build(:member, email: nil)
      expect(member).not_to be_valid
      expect(member.errors[:email]).to include("can't be blank")
    end

    it "does not require pt_school_application_date in the default context" do
      expect(build(:member)).to be_valid
    end

    it "requires pt_school_application_date in the :profile context" do
      member = build(:member, pt_school_application_date: nil)
      expect(member.valid?(:profile)).to be false
      expect(member.errors[:pt_school_application_date]).to include("can't be blank")
    end
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

    it "never exposes an unshared legacy phone number" do
      profile.phone_number = "979-555-0123"
      expect(profile.shared_phone_number).to be_nil
    end
  end

  describe "associations" do
    it "belongs to a role" do
      expect(Member.reflect_on_association(:role).macro).to eq(:belongs_to)
    end

    it "destroys dependent rsvps when the member is destroyed" do
      member = create(:member)
      create(:rsvp, member: member)

      expect { member.destroy }.to change(Rsvp, :count).by(-1)
    end

    it "destroys dependent attendances when the member is destroyed" do
      member = create(:member)
      create(:attendance, member: member, event: create(:event))

      expect { member.destroy }.to change(Attendance, :count).by(-1)
    end
  end

  describe "#profile_completed?" do
    it "is true when profile_completed_at is present" do
      expect(build(:member, :profile_completed)).to be_profile_completed
    end

    it "is false when profile_completed_at is nil (the default)" do
      expect(build(:member)).not_to be_profile_completed
    end
  end

  describe "#admin?" do
    it "is true for a member with the admin role" do
      expect(build(:member, :admin).admin?).to be true
    end

    it "is false for a member with a non-admin role" do
      expect(build(:member).admin?).to be false
    end

    it "is false when the member has no role" do
      expect(build(:member, role: nil).admin?).to be false
    end
  end

  describe ".from_google" do
    let(:google_params) do
      {
        email: "New.Student@tamu.edu",
        first_name: "New",
        last_name: "Student",
        uid: "12345",
        avatar_url: "https://example.com/avatar.png"
      }
    end

    it "returns nil for a non-tamu.edu email" do
      result = Member.from_google(**google_params.merge(email: "someone@gmail.com"))
      expect(result).to be_nil
    end

    it "creates a new member with a default Member role and today's join date" do
      expect { Member.from_google(**google_params) }.to change(Member, :count).by(1)

      member = Member.find_by(email: "new.student@tamu.edu")
      expect(member.first_name).to eq("New")
      expect(member.last_name).to eq("Student")
      expect(member.role.description).to eq("Member")
      expect(member.joined_at).to eq(Date.current)
    end

    it "reuses an existing Member role instead of creating a duplicate" do
      create(:role)

      expect { Member.from_google(**google_params) }.not_to change(Role, :count)
    end

    it "finds and updates an existing member by email instead of duplicating them" do
      existing = create(:member, email: "new.student@tamu.edu", uid: "old-uid")

      expect { Member.from_google(**google_params) }.not_to change(Member, :count)

      existing.reload
      expect(existing.uid).to eq("12345")
      expect(existing.avatar_url).to eq("https://example.com/avatar.png")
    end
  end
end
