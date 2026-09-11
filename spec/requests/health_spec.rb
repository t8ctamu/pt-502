require "rails_helper"

RSpec.describe "Application health", type: :request do
  it "responds successfully to the Rails health check" do
    get "/up"
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
  end

  it "returns not found for an unknown route" do
    get "/this-route-does-not-exist"
    expect(response).to have_http_status(:not_found)
  end
end
