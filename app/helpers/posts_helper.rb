module PostsHelper
  def post_link_with_image(post)
    return unless post.trip && post.id

    content_tag(:div, class: "d-flex flex-row gap-1") do
      (post.user.image_as_thumbnail.present? ?
        image_tag(post.user.image_as_thumbnail, class: "rounded-circle", style: "height: 22px; width: 22px;") :
        content_tag(:i, "", class: "bi bi-person-circle", style: "font-size: 1.3em; color: #333;")) +
      link_to(post.title, trip_path(post.trip, anchor: "post_#{post.id}"), data: { turbo_frame: "frame_id" }, target: "_top")
    end
  end
end
