class AddDraftToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :draft, :boolean, default: false, null: false
    add_column :posts, :notified_at, :datetime, default: nil
    add_index :posts, :draft
    add_index :posts, :notified_at

    Post.all.update_all(notified_at: Time.current)
  end
end
