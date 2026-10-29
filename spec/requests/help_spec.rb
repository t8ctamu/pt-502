require "rails_helper"

RSpec.describe "Help guides", type: :request do
     it "offers a direct return to login on public guides without needing a referring page" do
          [ help_path, member_help_path ].each do |path|
               get path
               document = Nokogiri::HTML(response.body)
               login = document.at_css('.help-navigation a')
               expect(login.text).to eq("Back to login")
               expect(login["href"]).to eq(new_member_session_path)

               get login["href"]
               expect(response).to have_http_status(:ok)
          end
     end

     it "offers sign-in help before authentication" do
          get new_member_session_path
          expect(response.body).to include(member_help_path)
          [ help_path, member_help_path ].each do |path|
               get path
               expect(response).to have_http_status(:ok)
          end
     end

     it "requires sign-in for officer and system guides" do
          [ officer_help_path, system_help_path ].each do |path|
               get path
               expect(response).to redirect_to(new_member_session_path)
          end
     end

     it "keeps regular members out of officer and system guides" do
          sign_in create(:member, :profile_completed)
          get help_path
          expect(response.body).not_to include(officer_help_path, system_help_path)
          [ officer_help_path, system_help_path ].each do |path|
               get path
               expect(response).to redirect_to(root_path)
          end
     end

     it "allows officers to read the guides before finishing their profile" do
          sign_in create(:member, :admin, :incomplete_profile)
          [ officer_help_path, system_help_path ].each do |path|
               get path
               expect(response).to have_http_status(:ok)
          end
     end

     it "serves app training separately from the offline system guide" do
          sign_in create(:member, :manager, :profile_completed)
          [ member_help_path, officer_help_path ].each do |path|
               get path
               expect(response.body).not_to match(/Heroku|DATABASE_URL|rails runner/)
          end
          get system_help_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Heroku", "system:bootstrap", "Failed import", "$12")
          expect(response.body).to eq(Rails.root.join("docs/system-guide.html").read)
     end

     it "renders live guide links, valid contents anchors, and real screenshot assets" do
          sign_in create(:member, :manager, :profile_completed)
          [ help_path, member_help_path, officer_help_path, system_help_path ].each do |path|
               get path
               expect(response).to have_http_status(:ok)
               document = Nokogiri::HTML(response.body)
               document.css('a[href^="#"]').each do |link|
                    expect(document.at_css("[id='#{link['href'].delete_prefix('#')}']")).to be_present
               end
               document.css('a[href^="/help"]').each do |link|
                    get link["href"].split("#").first
                    expect(response).to have_http_status(:ok)
               end
               document.css(".help-figure img").each do |image|
                    expect(image["alt"]).to be_present
                    filename = image["src"].split("/").last.sub(/-[a-f0-9]+(?=\.jpg\z)/, "")
                    asset = Rails.root.join("app/assets/images/help", filename)
                    expect(asset).to be_file
                    expect(asset.binread.start_with?("\xFF\xD8".b)).to be true
               end
          end
     end
end
