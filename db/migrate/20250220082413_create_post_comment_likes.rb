class CreatePostCommentLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :post_comment_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post_comment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
