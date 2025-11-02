module TripsHelper
  def generated_points(trip, pagy)
    trip.visible_posts.with_location
        .order(created_at: :desc)
        .map do |post|
      {
        postId: post.id,
        label: post.title,
        tooltip: post_link_with_image(post, pagy),
        locations: post.post_locations.map do |location|
          {
            travelType: location.travel_type,
            postLocationId: location.id,
            latitude: location.latitude,
            longitude: location.longitude
          }
        end
      }
    end.to_json
  end
end
