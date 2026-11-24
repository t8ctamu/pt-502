require "rails_helper"
require "tempfile"

RSpec.describe "Import file safety", type: :request do
     before { sign_in create(:member, :admin, :profile_completed) }

  [ "imports", "event_imports" ].each do |resource|
       context resource do
            let(:token) { SecureRandom.uuid }
         let(:directory) { Rails.root.join("tmp", resource) }
         let(:path) { directory.join("#{token}.csv") }

         before { FileUtils.mkdir_p(directory) }
         after { File.unlink(path) if File.symlink?(path) }

         it "rejects symlinks without reading or deleting the target" do
              Tempfile.create([ "outside-import-", ".csv" ]) do |target|
                   target.write("private data")
                target.flush
                File.symlink(target.path, path)

                get "/#{resource}/#{token}/preview"
                expect(response).to redirect_to("/#{resource}/new")
                expect(flash[:alert]).to include("Import expired")

                post "/#{resource}/#{token}/confirm"
                expect(response).to redirect_to("/#{resource}/new")
                expect(File.read(target.path)).to eq("private data")
              end
         end

         it "rejects glob characters in a token" do
              get "/#{resource}/#{'a' * 35}*/preview"
           expect(response).to redirect_to("/#{resource}/new")
           expect(flash[:alert]).to eq("Invalid import.")
         end

         it "rejects a directory masquerading as an upload" do
              Dir.mkdir(path)
           begin
                get "/#{resource}/#{token}/preview"
                expect(response).to redirect_to("/#{resource}/new")
                expect(flash[:alert]).to include("Import expired")
              ensure
                   Dir.rmdir(path)
           end
         end
       end
  end
end
