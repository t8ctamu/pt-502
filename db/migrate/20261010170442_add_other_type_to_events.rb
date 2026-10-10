class AddOtherTypeToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :other_type, :string
  end
end