require "rails_helper"

RSpec.describe MemberImport::Mapper do
     let(:mapping) { { "0" => "email", "1" => "full_name", "2" => "paid_dues" } }

  def map(rows)
       described_class.new(rows: rows, mapping: mapping).preview
  end

  it "marks valid rows as :valid" do
       row = map([ [ "alice@tamu.edu", "Alice Nguyen", "True" ] ]).first
    expect(row.status).to eq(:valid)
    expect(row.attributes).to include(
      email: "alice@tamu.edu", first_name: "Alice",
      last_name: "Nguyen", paid_dues: true
    )
  end

  it "flags missing emails" do
       row = map([ [ "", "Alice Nguyen", "True" ] ]).first
    expect(row.status).to eq(:error)
    expect(row.errors).to include("Missing email")
  end

  it "flags invalid emails" do
       row = map([ [ "not-an-email", "Alice", "True" ] ]).first
    expect(row.errors).to include("Invalid email")
  end

  it "marks rows as :skip when the email already exists" do
       create(:member, email: "alice@tamu.edu")
    row = map([ [ "alice@tamu.edu", "Alice", "True" ] ]).first
    expect(row.status).to eq(:skip)
  end
end
