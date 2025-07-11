class AddHiddenToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :hidden, :boolean, default: false, null: false
    add_index :posts, :hidden
  end
end
