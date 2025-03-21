class AddTravelTypeToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :travel_type, :integer, default: 0
  end
end
