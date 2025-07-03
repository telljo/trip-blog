module TripsHelper
  def generated_points(trip, pagy)
    trip.posts.with_location.order(created_at: :desc).map do |post|
      {
        postId: post.id,
        latitude: post.latitude,
        longitude: post.longitude,
        label: post.title,
        tooltip: post_link_with_image(post, pagy),
        travelType: post.travel_type
      }
    end.to_json
  end
end
