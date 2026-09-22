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