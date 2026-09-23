class Role < ApplicationRecord
  LEVELS = { "Member" => 0, "Admin" => 1, "Manager" => 2 }.freeze

  def level
    LEVELS.fetch(description, -1)
  end

  def manager?
    level >= 2
  end

  def admin?
    level >= 1
  end
end
