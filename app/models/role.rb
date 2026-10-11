class Role < ApplicationRecord
  LEVELS = { "member" => 0, "admin" => 1, "manager" => 2 }.freeze

  def level
    LEVELS.fetch(description.to_s.downcase, -1)
  end

  def manager?
    level >= 2
  end

  def admin?
    level >= 1
  end
end
