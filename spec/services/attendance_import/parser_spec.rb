require "rails_helper"

RSpec.describe AttendanceImport::Parser do
     let(:csv_path) { Rails.root.join("spec/fixtures/files/attendance_import_sample.csv").to_s }

     it "returns the header row" do
          expect(described_class.new(csv_path).headers).to eq(
               [ "Checked In", "Entries", "# in Party", "First Name", "Last Name", "Email", "Card Issuer" ]
          )
     end

     it "returns data rows without the header" do
          rows = described_class.new(csv_path).rows
          expect(rows.size).to eq(2)
          expect(rows.first[5]).to eq("ktmd3368@email.tamu.edu")
     end
end
