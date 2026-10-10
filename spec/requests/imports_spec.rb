require "rails_helper"

RSpec.describe "Imports", type: :request do
     let(:admin)   { create(:member, :admin, :profile_completed) }
  let(:regular) { create(:member, :profile_completed) }

  describe "GET /imports/new" do
       it "shows the form to admins" do
            sign_in admin
         get new_import_path
         expect(response).to have_http_status(:ok)
         expect(response.body).to include("Import Members")
       end

    it "redirects regular members" do
         sign_in regular
      get new_import_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /imports" do
       before { sign_in admin }

    it "rejects non-csv uploads" do
         file = Rack::Test::UploadedFile.new(
           Rails.root.join("spec/fixtures/files/bad.txt"), "text/plain"
         )
      post imports_path, params: { file: file }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please upload a .csv file")
    end

    it "stores the file and redirects to preview" do
         allow(MemberImport::Parser).to receive(:new).and_return(
           instance_double(MemberImport::Parser, headers: [ "Email" ], rows: [])
         )
      file = Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/members.csv"), "text/csv"
      )
      post imports_path, params: { file: file }
      expect(response).to redirect_to(%r{/imports/[0-9a-f-]+/preview})
    end
  end

  describe "POST /imports/:token/confirm" do
       before { sign_in admin }

    let(:token) { SecureRandom.uuid }
    let(:path)  { Rails.root.join("tmp", "imports", "#{token}.csv") }

    before do
         FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, "Email\nnew@tamu.edu\n")
      allow(MemberImport::Parser).to receive(:new).and_return(
        instance_double(MemberImport::Parser,
          headers: [ "Email" ],
          rows: [ [ "new@tamu.edu" ] ])
      )
    end

    it "creates members and shows the summary" do
         expect {
              post confirm_import_path(token), params: { mapping: { "0" => "email" } }
         }.to change(Member, :count).by(1)
      expect(response.body).to include("1 members added")
    end
  end

  describe "GET /imports/:token/preview with malformed CSV" do
       before { sign_in admin }

    let(:token) { SecureRandom.uuid }
    let(:path)  { Rails.root.join("tmp", "imports", "#{token}.csv") }

    before do
         FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, %(Email,Name\n"unterminated,Alice\n))
    end

    it "redirects back to new with an alert" do
         get preview_import_path(token)
      expect(response).to redirect_to(new_import_path)
      follow_redirect!
      expect(CGI.unescapeHTML(response.body)).to include("isn't valid CSV")
    end
  end
end
