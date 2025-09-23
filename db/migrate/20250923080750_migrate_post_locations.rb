class MigratePostLocations < ActiveRecord::Migration[8.0]
  def up
    # Iterate through all posts and create associated locations
    Post.find_each do |post|
      if post.latitude.present? && post.longitude.present?
        PostLocation.create!(
          post_id: post.id,
          latitude: post.latitude,
          longitude: post.longitude,
          street: post.street,
          city: post.city,
          state: post.state,
          country: post.country
        )
      end
    end

    # Optionally, remove location columns from posts table
    remove_column :posts, :latitude
    remove_column :posts, :longitude
    remove_column :posts, :street
    remove_column :posts, :city
    remove_column :posts, :state
    remove_column :posts, :country
  end

  def down
    # Rollback: Add location columns back to posts table
    add_column :posts, :latitude, :float
    add_column :posts, :longitude, :float
    add_column :posts, :street, :string
    add_column :posts, :city, :string
    add_column :posts, :state, :string
    add_column :posts, :country, :string

    # Restore location data from locations table
    PostLocation.find_each do |location|
      post = Post.find_by(id: location.post_id)
      next unless post

      post.update!(
        latitude: location.latitude,
        longitude: location.longitude,
        street: location.street,
        city: location.city,
        state: location.state,
        country: location.country
      )
    end
  end
end
