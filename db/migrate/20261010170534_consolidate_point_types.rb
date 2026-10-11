class ConsolidatePointTypes < ActiveRecord::Migration[8.1]
     class Req < ApplicationRecord; self.table_name = "requirements"; end
  class Pt  < ApplicationRecord; self.table_name = "points";       end
  class Ev  < ApplicationRecord; self.table_name = "events";       end

  def up
       Req.find_by(name: "Service")&.update!(minimum_points: 1)
    Req.find_by(name: "Professional/Development")&.update!(name: "Professionalism", minimum_points: 1)

    other = Req.find_by(name: "Other")
    return unless other
    other.update!(minimum_points: 0)

    Req.where(name: %w[Social Fundraising]).each do |old|
         Ev.where(requirement_id: old.id).update_all(other_type: old.name)
      Ev.where(requirement_id: old.id).update_all(requirement_id: other.id)
      Pt.where(requirement_id: old.id).update_all(requirement_id: other.id)
      old.delete
    end
  end

  def down
       raise ActiveRecord::IrreversibleMigration
  end
end
