module MemberImport
  class Executor
    def initialize(preview_rows)
      @rows = preview_rows
      @role = Role.find_by!(description: "Member")
    end

    def call
      created = 0
      Member.transaction do
        @rows.each do |row|
          next unless row.status == :valid

          member = Member.create!(
            row.attributes.merge(role: @role, joined_at: Date.current)
          )

          Array(row.points).each do |p|
            member.point_entries.create!(
              requirement_id: p[:requirement_id],
              point_amount: p[:point_amount],
              awarded_date: Date.current,
              note: "Imported from spreadsheet"
            )
          end

          created += 1
        end
      end
      created
    end
  end
end