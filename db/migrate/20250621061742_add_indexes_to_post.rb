class AddIndexesToPost < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :country
  end
end
