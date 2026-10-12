require "rails_helper"

RSpec.describe EventImport::Executor do
     let(:requirement) { create(:requirement, name: "Service") }
  let(:other_requirement) { create(:requirement, name: "Other") }

  before do
       allow_any_instance_of(Geocoding::Nominatim).to receive(:search).and_return([])
  end

  def preview_row(status:, index: 2, attrs: {})
       start_time = attrs.delete(:starts_at) || 1.week.from_now
    end_time   = attrs.delete(:ends_at)   || start_time + 1.hour

    EventImport::Mapper::Row.new(
      index: index,
      raw: [],
      attributes: {
        external_reference: "EVN-#{index}",
        name: "Imported Event #{index}",
        starts_at: start_time,
        ends_at: end_time,
        description: "Test event",
        location: "MSC"
      }.merge(attrs),
      status: status,
      errors: [],
      existing_event: nil
    )
  end

  it "creates events for :new rows and returns count" do
       rows = [ preview_row(status: :new, index: 2) ]
    assignments = { 2 => { requirement_id: requirement.id.to_s, point_value: "2" } }

    result = described_class.new(rows: rows, assignments: assignments).call

    expect(result.created).to eq(1)
    expect(Event.find_by(external_reference: "EVN-2")).to be_present
    expect(Event.find_by(external_reference: "EVN-2").point_value).to eq(2)
  end

  it "skips :skip rows" do
       rows = [ preview_row(status: :skip) ]

    result = described_class.new(rows: rows, assignments: {}).call

    expect(result.skipped).to eq(1)
    expect(Event.count).to eq(0)
  end

  it "collects :error rows" do
       error_row = preview_row(status: :error)
    error_row.errors << "Missing something"

    result = described_class.new(rows: [ error_row ], assignments: {}).call

    expect(result.errored.size).to eq(1)
  end

  it "updates existing events for :update rows" do
       existing = create(:event, external_reference: "EVN-5", name: "Old Name")
    row = preview_row(status: :update, index: 5, attrs: { name: "New Name" })
    row.existing_event = existing

    result = described_class.new(rows: [ row ], assignments: {}).call

    expect(result.updated).to eq(1)
    expect(existing.reload.name).to eq("New Name")
  end

  it "decodes HTML entities in description" do
       row = preview_row(status: :new, index: 2, attrs: { description: "A &amp; B" })
    assignments = { 2 => { requirement_id: requirement.id.to_s } }

    described_class.new(rows: [ row ], assignments: assignments).call

    expect(Event.find_by(external_reference: "EVN-2").description).to eq("A & B")
  end

  it "geocodes the location when creating" do
       allow_any_instance_of(Geocoding::Nominatim).to receive(:search).and_return(
         [ { label: "Memorial Student Center", latitude: 30.628, longitude: -96.334 } ]
       )

    row = preview_row(status: :new, index: 2)
    described_class.new(rows: [ row ], assignments: { 2 => { requirement_id: requirement.id.to_s } }).call

    event = Event.find_by(external_reference: "EVN-2")
    expect(event.latitude).to be_within(0.001).of(30.628)
    expect(event.longitude).to be_within(0.001).of(-96.334)
  end
end
