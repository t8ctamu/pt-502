require "rails_helper"

RSpec.describe AttendanceImport::Mapper do
     let(:headers) do
          [ "Checked In", "Entries", "# in Party", "First Name", "Last Name", "Email", "Card Issuer" ]
     end

     let!(:member) { create(:member, email: "ktmd3368@email.tamu.edu") }

     def build_row(checked_in: "2026-10-06 22:33:31", email: "ktmd3368@email.tamu.edu")
          [ checked_in, "1", "1", "Mennah", "Dia", email, "" ]
     end

     subject(:mapper) { described_class.new(headers: headers, rows: rows) }

     context "with a valid row for an existing member" do
          let(:rows) { [ build_row ] }

          it "marks the row :ready and resolves the member and time" do
               row = mapper.preview.first
               expect(row.status).to eq(:ready)
               expect(row.member).to eq(member)
               expect(row.checked_in_at).to be_a(Time)
               expect(row.index).to eq(2)
          end
     end

     context "with an unknown email" do
          let(:rows) { [ build_row(email: "ghost@email.tamu.edu") ] }

          it "marks the row :error with a reason" do
               row = mapper.preview.first
               expect(row.status).to eq(:error)
               expect(row.errors).to include(/No member found/)
          end
     end

     context "with an unreadable Checked In value" do
          let(:rows) { [ build_row(checked_in: "not a timestamp") ] }

          it "marks the row :error with a reason" do
               row = mapper.preview.first
               expect(row.status).to eq(:error)
               expect(row.errors).to include(/Could not read Checked In/)
          end
     end

     context "with a blank Checked In value" do
          let(:rows) { [ build_row(checked_in: "") ] }

          it "marks the row :error with a missing-timestamp reason" do
               row = mapper.preview.first
               expect(row.status).to eq(:error)
               expect(row.errors).to include(/Missing Checked In/)
          end
     end
end
