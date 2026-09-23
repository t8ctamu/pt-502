module HomeHelper
  def display_role(member)
    member.role.description == "Admin" ? "Officer" : member.role.description
  end
end