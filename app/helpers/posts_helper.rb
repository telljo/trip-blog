module PostsHelper
  def html_link_to(post)
    link_to post.title, trip_path(post.trip, anchor: "post_#{post.id}"), data: { turbo_frame: "frame_id" }, target: "_top"
  end
end
