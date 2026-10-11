namespace :system do
     desc "Set up default point types and the first manager (EMAIL, FIRST_NAME, LAST_NAME required)"
     task bootstrap: :environment do
          email = ENV.fetch("EMAIL", "").strip.downcase
          first_name = ENV.fetch("FIRST_NAME", "").strip
          last_name = ENV.fetch("LAST_NAME", "").strip
          abort "Provide EMAIL ending in @tamu.edu, FIRST_NAME, and LAST_NAME." unless
               email.match?(/\A[^\s@]+@tamu\.edu\z/) && first_name.present? && last_name.present?

          ActiveRecord::Base.transaction do
               roles = %w[Member Admin Manager].index_with { |name| Role.find_or_create_by!(description: name) }
               owner = Member.find_or_initialize_by(email: email)
               other_managers = Member.joins(:role).where("LOWER(roles.description) = ?", "manager").where.not(email: email)
               abort "A manager already exists. Use the club's access handover process." if other_managers.exists?

               [ [ "Service", 1 ], [ "Professionalism", 1 ], [ "Other", 0 ] ].each do |name, minimum|
                    Requirement.find_or_create_by!(name: name) { |type| type.minimum_points = minimum }
               end
               AppSetting.current
               owner.assign_attributes(role: roles.fetch("Manager"))
               owner.first_name ||= first_name
               owner.last_name ||= last_name
               owner.joined_at ||= Date.current
               owner.save!
          end
          puts "Initial manager is ready. Sign in with that Google account and finish the profile."
     end
end
