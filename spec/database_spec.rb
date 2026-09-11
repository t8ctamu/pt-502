require "rails_helper"

RSpec.describe "Test database" do
  it "connects to the isolated PostgreSQL test database" do
    connection = ActiveRecord::Base.connection
    expect(connection.select_value("SELECT current_database()")).to eq("pt502_test")
    expect(connection.select_value("SELECT 1")).to eq(1)
  end
end
