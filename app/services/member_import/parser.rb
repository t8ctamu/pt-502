require "csv"

module MemberImport
  class Parser
    def initialize(path)
      @path = path.to_s
    end

    def headers
      @headers ||= all_rows.first.to_a.map(&:to_s)
    end

    def rows
      @rows ||= all_rows.drop(1).map { |r| r.map { |v| v.to_s } }
    end

    private

    def all_rows
      @all_rows ||= CSV.read(@path, headers: false, encoding: "bom|utf-8")
    end
  end
end