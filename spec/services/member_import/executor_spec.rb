require "rails_helper"

RSpec.describe MemberImport::Executor do
     let(:valid_row) do
          MemberImport::Mapper::Row.new(
            index: 2,
            raw: [],
            attributes: { email: "new@tamu.edu", first_name: "New", last_name: "Person" },
            points: [],
            status: :valid,
            errors: []
          )
     end

  let(:error_row) do
       MemberImport::Mapper::Row.new(
         index: 3,
         raw: [],
         attributes: {},
         points: [],
         status: :error,
         errors: [ "Missing email" ]
       )
  end

  let(:skip_row) do
       MemberImport::Mapper::Row.new(
         index: 4,
         raw: [],
         attributes: {},
         points: [],
         status: :skip,
         errors: []
       )
  end

  it "creates only the valid rows" do
       expect {
            described_class.new([ valid_row, error_row, skip_row ]).call
       }.to change(Member, :count).by(1)
  end
end
