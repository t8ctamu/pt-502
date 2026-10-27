require "rails_helper"

RSpec.describe EventImport::Parser do
     let(:csv_path) { Rails.root.join("spec/fixtures/files/events.csv").to_s }

  describe "#headers" do
       it "returns the first row as headers" do
            parser = described_class.new(csv_path)
         expect(parser.headers).to eq(
           [ "Reference", "Type", "Title", "Organization", "Starts", "Ends",
             "Status", "Location", "Location Detail", "Marketing Blurb",
             "Visibility", "Event Planner" ]
         )
       end
  end

  describe "#rows" do
       it "returns the data rows without the header" do
            parser = described_class.new(csv_path)
         expect(parser.rows.size).to eq(4)
         expect(parser.rows.first[0]).to eq("EVN-26994")
       end
  end

  it "reads the same headers and mixed-status rows from an Excel export" do
       csv = described_class.new(csv_path)
    excel = described_class.new(Rails.root.join("spec/fixtures/files/events.xlsx"))

    expect(excel.headers).to eq(csv.headers)
    expect(excel.rows).to eq(csv.rows)
  end
end
