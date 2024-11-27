module TripsHelper
  def generated_points(trip)
    trip.posts.with_location.order(created_at: :desc).map do |post|
      {
        postId: post.id,
        latitude: post.latitude,
        longitude: post.longitude,
        label: post.title,
        tooltip: html_link_to(post)
      }
    end.to_json
  end
end
