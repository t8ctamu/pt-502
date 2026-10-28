require "roo"

module AttendanceImport
     class Parser
          def initialize(path)
               @path = path.to_s
          end

          def headers
               @headers ||= spreadsheet.row(1).map(&:to_s)
          end

          def rows
               @rows ||= (2..spreadsheet.last_row).map do |i|
                    spreadsheet.row(i).map { |v| v.to_s }
               end
          end

          private

               def spreadsheet
                    @spreadsheet ||= if File.extname(@path).downcase == ".csv"
                         Roo::CSV.new(@path)
                    else
                         Roo::Excelx.new(@path)
                    end
               end
     end
end
