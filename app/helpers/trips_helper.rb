module TripsHelper
  def generated_points(trip, pagy)
    trip.visible_posts.with_location.order(created_at: :desc).flat_map do |post|
      post.post_locations.map do |location|
        {
          postId: post.id,
          latitude: location.latitude,
          longitude: location.longitude,
          label: post.title,
          tooltip: post_link_with_image(post, pagy),
          travelType: post.travel_type
        }
      end
    end.to_json
  end
end
