module ProfilesHelper
  def graduation_term_options(member)
    years = profile_years(member.expected_graduation_term.to_s[/\d{4}\z/].to_i)
    years.flat_map { |year| %w[Spring Summer Fall].map { |term| "#{term} #{year}" } }
  end

  def application_cycle_options(member)
    profile_years(member.pt_school_application_date&.year).map do |year|
      [ "Summer #{year}", Date.new(year, 6, 1).iso8601 ]
    end
  end

  def profile_field_options(member, field, hint: nil)
    descriptions = [ hint ]
    descriptions << "member_#{field}_error" if member.errors[field].any?
    { aria: { invalid: member.errors[field].any?, describedby: descriptions.compact.join(" ").presence } }
  end

  private

  def profile_years(saved_year)
    years = (Date.current.year..Date.current.year + 15).to_a
    years << saved_year if saved_year.present? && saved_year.positive?
    years.uniq.sort
  end
end
