class AddUserIdToPosts < ActiveRecord::Migration[8.0]
  def up
    add_column :posts, :user_id, :integer

    Post.reset_column_information
    Post.all.each do |post|
      post.update(user_id: post.trip.user_id)
    end
  end

  def down
    remove_column :posts, :user_id
  end
end
