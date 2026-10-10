class AddRequirementAndPointLinks < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :requirement, foreign_key: true, null: true
    add_reference :attendances, :point, foreign_key: true, null: true, index: { unique: true }
  end
end