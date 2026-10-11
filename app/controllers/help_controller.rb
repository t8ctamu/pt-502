class HelpController < ApplicationController
     skip_before_action :authenticate_member!, only: %i[index member]
     before_action :require_admin, only: %i[officer system]

     def index
     end

     def member
     end

     def officer
     end

     def system
          render file: Rails.root.join("docs/system-guide.html"), layout: false
     end
end
