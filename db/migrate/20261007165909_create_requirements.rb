class CreateRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :requirements do |t|
      t.string  :name, null: false
      t.text    :description
      t.integer :minimum_points, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :requirements, :name, unique: true
    add_check_constraint :requirements, "minimum_points >= 0", name: "requirements_minimum_nonnegative"
  end
end