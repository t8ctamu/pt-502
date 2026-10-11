require "rails_helper"
require_relative "../../db/migrate/20261009084832_add_contact_fields_to_members"
require_relative "../../db/migrate/20261011000000_add_member_profile_details"
require_relative "../../db/migrate/20261011000001_consolidate_member_phone_consent"

RSpec.describe "Member phone migrations" do
     let(:connection) { ActiveRecord::Base.connection }

  before do
       connection.execute(<<~SQL)
      CREATE TEMP TABLE members (
        id bigint PRIMARY KEY,
        phone_number varchar,
        phone_visible boolean NOT NULL DEFAULT false,
        share_phone_number boolean NOT NULL DEFAULT false
      ) ON COMMIT DROP
    SQL
  end

  after do
       connection.execute("DROP TABLE IF EXISTS pg_temp.members")
    Member.reset_column_information
  end

  it "preserves numbers and consent from either branch and can restore the old flag" do
       connection.execute(<<~SQL)
      INSERT INTO members VALUES
        (1, '979-555-0101', true, false),
        (2, '979-555-0102', false, true),
        (3, '979-555-0103', false, false)
    SQL
    migration = ConsolidateMemberPhoneConsent.new
    migration.up

    expect(connection.select_values("SELECT phone_number FROM members ORDER BY id")).to eq(%w[979-555-0101 979-555-0102 979-555-0103])
    expect(connection.select_values("SELECT phone_visible FROM members ORDER BY id")).to eq([ true, true, false ])
    expect(connection.columns(:members).map(&:name)).not_to include("share_phone_number")

    migration.down
    expect(connection.select_values("SELECT share_phone_number FROM members ORDER BY id")).to eq([ true, true, false ])
  end

  it "upgrades a database that already has the profile story's phone field" do
       connection.remove_column(:members, :phone_visible)
    connection.execute("INSERT INTO members (id, phone_number, share_phone_number) VALUES (1, '979-555-0101', true)")

    AddContactFieldsToMembers.new.change
    ConsolidateMemberPhoneConsent.new.up

    expect(connection.select_value("SELECT phone_number FROM members")).to eq("979-555-0101")
    expect(connection.select_value("SELECT phone_visible FROM members")).to be true
  end

  it "reuses the contact fields already added on main" do
       connection.remove_column(:members, :share_phone_number)
    connection.execute("INSERT INTO members (id, phone_number, phone_visible) VALUES (1, '979-555-0101', true)")

    AddMemberProfileDetails.new.change
    ConsolidateMemberPhoneConsent.new.up

    expect(connection.select_value("SELECT phone_number FROM members")).to eq("979-555-0101")
    expect(connection.select_value("SELECT phone_visible FROM members")).to be true
    expect(connection.columns(:members).map(&:name)).to include("expected_graduation_term")
  end
end
