class CreatePostCommentReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :post_comment_replies do |t|
      t.text :content
      t.references :post_comment, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
