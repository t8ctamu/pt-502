require "rails_helper"

RSpec.describe EventImport::Mapper do
     let(:headers) do
          [ "Reference", "Type", "Title", "Organization", "Starts", "Ends",
            "Status", "Location", "Location Detail", "Marketing Blurb",
            "Visibility", "Event Planner" ]
     end

  def build_row(reference:, title:, starts:, status: "Approved", location: "MSC", detail: "MSC 2406A")
       [ reference, "Event", title, "Physical Therapy Society", starts,
         "", status, location, detail, "Blurb", "None", "Hudson Lee" ]
  end

  subject(:mapper) { described_class.new(headers: headers, rows: rows) }

  context "with a valid approved row" do
       let(:rows) { [ build_row(reference: "EVN-100", title: "Test Event", starts: "Oct 14, 2026 4:30 pm") ] }

    it "marks the row as :new" do
         expect(mapper.preview.first.status).to eq(:new)
    end

    it "maps reference, title, starts_at, location" do
         row = mapper.preview.first
      expect(row.attributes[:external_reference]).to eq("EVN-100")
      expect(row.attributes[:name]).to eq("Test Event")
      expect(row.attributes[:starts_at]).to be_a(Time)
      expect(row.attributes[:location]).to eq("MSC — MSC 2406A")
    end
  end

  context "with status not Approved" do
       let(:rows) { [ build_row(reference: "EVN-100", title: "Draft", starts: "Oct 14, 2026 4:30 pm", status: "Submitted") ] }

    it "marks the row as :skip" do
         expect(mapper.preview.first.status).to eq(:skip)
    end
  end

  context "when the reference already exists on an event" do
       let!(:existing) { create(:event, external_reference: "EVN-200") }
    let(:rows) { [ build_row(reference: "EVN-200", title: "Updated", starts: "Oct 14, 2026 4:30 pm") ] }

    it "marks the row as :update" do
         expect(mapper.preview.first.status).to eq(:update)
      expect(mapper.preview.first.existing_event).to eq(existing)
    end
  end

  context "when the reference is missing" do
       let(:rows) { [ build_row(reference: "", title: "No Ref", starts: "Oct 14, 2026 4:30 pm") ] }

    it "marks the row as :error" do
         expect(mapper.preview.first.status).to eq(:error)
      expect(mapper.preview.first.errors).to include(/reference/)
    end
  end

  context "when starts_at can't be parsed" do
       let(:rows) { [ build_row(reference: "EVN-300", title: "Bad Date", starts: "not a date") ] }

    it "marks the row as :error" do
         expect(mapper.preview.first.status).to eq(:error)
      expect(mapper.preview.first.errors).to include(/Could not parse/)
    end
  end

  context "when both location fields are blank" do
       let(:rows) { [ build_row(reference: "EVN-400", title: "No Loc", starts: "Oct 14, 2026 4:30 pm", location: "", detail: "") ] }

    it "marks the row as :error" do
         expect(mapper.preview.first.status).to eq(:error)
    end
  end
end
