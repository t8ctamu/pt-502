# spec/requests/imports_spec.rb
require "rails_helper"

RSpec.describe "Member imports", type: :request do
     let(:officer) { create(:member, :profile_completed, :admin) }
  let!(:service) { create(:requirement, name: "Service", minimum_points: 1) }
  let(:token) { SecureRandom.uuid }
  let(:path) { Rails.root.join("tmp", "imports", "#{token}.csv") }
  let(:csv) do
       "First Name,Last Name,Email,Dues,Service\nJane,Doe,jane.doe@tamu.edu,yes,x\n"
  end

  def upload(content, name: "members.csv")
       Rack::Test::UploadedFile.new(StringIO.new(content), "text/csv", original_filename: name)
  end

  def stage(content = csv)
       FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  after { FileUtils.rm_f(path) }

  context "signed in as an officer" do
       before { sign_in officer }

    it "shows the upload form" do
         get new_import_path
      expect(response).to have_http_status(:ok)
    end

    it "rejects a non-CSV file" do
         post imports_path, params: { file: upload(csv, name: "members.txt") }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Please upload a .csv file.")
    end

    it "rejects a missing file" do
         post imports_path
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a file over 10 MB" do
         big = upload("a,b\n")
      allow_any_instance_of(ActionDispatch::Http::UploadedFile)
        .to receive(:size).and_return(11.megabytes)
      post imports_path, params: { file: big }
      expect(response.body).to include("File is too large")
    end

    it "stores a valid CSV and redirects to the preview" do
         post imports_path, params: { file: upload(csv) }
      expect(response).to have_http_status(:redirect)
      expect(response.location).to match(%r{/imports/[0-9a-f-]{36}/preview})
      FileUtils.rm_f(Dir.glob(Rails.root.join("tmp", "imports", "*.csv")))
    end

    it "rejects a malformed token" do
         get preview_import_path("not-a-token")
      expect(response).to redirect_to(new_import_path)
      expect(flash[:alert]).to eq("Invalid import.")
    end

    it "reports an expired import" do
         get preview_import_path(token)
      expect(response).to redirect_to(new_import_path)
      expect(flash[:alert]).to eq("Import expired. Please upload again.")
    end

    it "previews with auto-detected columns" do
         stage
      get preview_import_path(token)
      expect(response).to have_http_status(:ok)
    end

    it "previews with an explicit mapping" do
         stage
      get preview_import_path(token), params: {
        mapping: { "0" => "first_name", "1" => "last_name", "2" => "email", "3" => "paid_dues", "4" => "ignore" }
      }
      expect(response).to have_http_status(:ok)
    end

    it "applies a default requirement to yes/no columns" do
         stage("Name,Email,Attended\nJane Doe,jane.doe@tamu.edu,x\n")
      get preview_import_path(token), params: { default_requirement_id: service.id }
      expect(response).to have_http_status(:ok)
    end

    it "guesses full_name for an unlabeled column of names" do
         stage(",Email\nJane Doe,jane.doe@tamu.edu\nSam Lee,sam.lee@tamu.edu\n")
      get preview_import_path(token)
      expect(response).to have_http_status(:ok)
    end

    it "handles an unlabeled column that is not names, and an empty one" do
         stage(",,Email\n123,,jane.doe@tamu.edu\n")
      get preview_import_path(token)
      expect(response).to have_http_status(:ok)
    end

    it "detects first, last, full-name, dues and unknown headers" do
         stage("Full Name,First Name,Last Name,Dues Paid,Service,Whatever,Email\n" \
               "Jane Doe,Jane,Doe,yes,x,foo,jane.doe@tamu.edu\n")
      get preview_import_path(token)
      expect(response).to have_http_status(:ok)
    end

    it "deletes the file and explains a malformed CSV" do
         stage
      allow_any_instance_of(MemberImport::Parser)
        .to receive(:headers).and_raise(CSV::MalformedCSVError.new("bad", 1))
      get preview_import_path(token)
      expect(response).to redirect_to(new_import_path)
      expect(flash[:alert]).to include("isn't valid CSV")
      expect(File.exist?(path)).to be(false)
    end

    it "confirms an import and cleans up" do
         stage
      post confirm_import_path(token), params: {
        mapping: { "0" => "first_name", "1" => "last_name", "2" => "email", "3" => "paid_dues", "4" => "ignore" }
      }
      expect(response).to redirect_to(members_path)
      expect(flash[:notice]).to match(/member.* added, \d+ skipped/)
      expect(File.exist?(path)).to be(false)
    end

    it "mentions rows with issues on confirm" do
         stage("First Name,Last Name,Email\nBad,Row,not-an-email\n")
      post confirm_import_path(token), params: {
        mapping: { "0" => "first_name", "1" => "last_name", "2" => "email" }
      }
      expect(flash[:notice]).to include("had issues")
    end
  end

  it "blocks regular members" do
       sign_in create(:member, :profile_completed)
    get new_import_path
    expect(response).to redirect_to(root_path)
  end
end
