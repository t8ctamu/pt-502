module MemberImport
     class Mapper
          Row = Struct.new(:index, :raw, :attributes, :points, :status, :errors, keyword_init: true)

       MEMBER_FIELDS = %w[email first_name last_name full_name paid_dues].freeze
       REQUIREMENT_PREFIX = "requirement:".freeze
       TRUTHY = %w[true yes y x].freeze
       FALSY  = %w[false no n].freeze

       def initialize(rows:, mapping:)
            @rows = rows
         @mapping = mapping.to_h.transform_keys(&:to_s).transform_values(&:to_s)
       end

       def preview
            @preview ||= @rows.each_with_index.map { |raw, i| build_row(i, raw) }
       end

       private

            def build_row(index, raw)
                 attrs = {}
              points = []

              @mapping.each do |col, field|
                   value = raw[col.to_i].to_s.strip

                if field.start_with?(REQUIREMENT_PREFIX)
                     req_id = field.delete_prefix(REQUIREMENT_PREFIX).to_i
                  amount = points_from_value(value)
                  points << { requirement_id: req_id, point_amount: amount } if amount.positive?
                elsif MEMBER_FIELDS.include?(field)
                     apply_member_field(attrs, field, value)
                end
              end

              errors = validate(attrs)
              status = if errors.any? then :error
              elsif duplicate?(attrs[:email]) then :skip
              else :valid
              end

              Row.new(index: index + 2, raw: raw, attributes: attrs, points: points,
                      status: status, errors: errors)
            end

       def points_from_value(value)
            v = value.to_s.strip.downcase
         return 0 if v.empty?
         return 0 if FALSY.include?(v)
         return 1 if TRUTHY.include?(v)

         n = Integer(v, exception: false)
         n && n.positive? ? n : 0
       end

       def apply_member_field(attrs, field, value)
            return if value.empty?

         case field
         when "full_name"
              parts = value.split(/\s+/)
           attrs[:first_name] ||= parts.first
           attrs[:last_name]  ||= parts[1..].join(" ") if parts.length > 1
         when "paid_dues"
              attrs[:paid_dues] = TRUTHY.include?(value.downcase)
         when "email"
              attrs[:email] = value.downcase
         else
              attrs[field.to_sym] = value
         end
       end

       def validate(attrs)
            errs = []
         errs << "Missing email" if attrs[:email].blank?
         if attrs[:email].present? && !attrs[:email].match?(URI::MailTo::EMAIL_REGEXP)
              errs << "Invalid email"
         end
         errs
       end

       def duplicate?(email)
            return false if email.blank?
         Member.where("LOWER(email) = ?", email.downcase).exists?
       end
     end
end
