require "rails_helper"

RSpec.describe ProfilesHelper, type: :helper do
  it "offers only summer application cycles encoded as June 1" do
    options = helper.application_cycle_options(build(:member))
    expect(options).to include([ "Summer #{Date.current.year}", Date.new(Date.current.year, 6, 1).iso8601 ])
    options.each do |label, value|
      expect(label).to match(/\ASummer \d{4}\z/)
      expect(Date.iso8601(value).month).to eq(6)
    end
  end

  it "preserves saved graduation and application years outside the usual list" do
    member = build(:member, expected_graduation_term: "Fall 2020", pt_school_application_date: Date.new(2050, 5, 1))
    expect(helper.graduation_term_options(member)).to include("Fall 2020")
    expect(helper.application_cycle_options(member)).to include([ "Summer 2050", "2050-06-01" ])
  end
end
