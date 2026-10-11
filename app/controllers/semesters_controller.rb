class SemestersController < ApplicationController
     before_action :require_completed_profile
  before_action :require_admin

  PER_PAGE = 50

  def index
       @semesters = Semester.order(starts_on: :desc)
  end

def show
     @semester = Semester.find(params[:id])
  @pagy, @members = pagy(:offset, Member.order(:last_name, :first_name), limit: PER_PAGE)

  member_ids = @members.map(&:id)
  @totals = Point.where(semester: @semester, member_id: member_ids)
                 .group(:member_id)
                 .sum(:point_amount)
end

  def reset
       current = AppSetting.current_semester

       if current && Date.current.between?(current.starts_on, current.ends_on)
            return redirect_to members_path,
              alert: "The current semester (#{current.name}) is still active. Wait until it ends to reset."
       end

       new_semester = Semester.create!(next_semester_attributes)

       AppSetting.current.update!(current_semester: new_semester)

       redirect_to members_path,
         notice: "Semester reset to #{new_semester.name}. Members now start at 0 points this semester."
     rescue ActiveRecord::RecordInvalid => e
          redirect_to members_path,
            alert: "Reset failed: #{e.record.errors.full_messages.to_sentence}"
  end

  private

       def next_semester_attributes
            current = AppSetting.current_semester

         if current.nil?
              year = Date.current.year
           return {
             name: "Fall #{year}",
             starts_on: Date.new(year, 8, 1),
             ends_on: Date.new(year, 12, 31)
           }
         end

         year = current.ends_on.year

         case current.name
         when /\ASpring/, /\ASummer/
              { name: "Fall #{year}", starts_on: Date.new(year, 8, 1), ends_on: Date.new(year, 12, 31) }
         when /\AFall/
              next_year = year + 1
           { name: "Spring #{next_year}", starts_on: Date.new(next_year, 1, 1), ends_on: Date.new(next_year, 5, 15) }
         else
              next_year = year + 1
           { name: "Fall #{next_year}", starts_on: Date.new(next_year, 8, 1), ends_on: Date.new(next_year, 12, 31) }
         end
       end
end
