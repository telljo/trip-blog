module PostsHelper
  def post_link_with_image(post, pagy)
    return unless post.trip && post.id

    content_tag(:div, class: "d-flex flex-row gap-1") do
      (post.user.image_as_tiny_avatar.present? ?
        tiny_avatar_image_tag(post.user, size: 22, class: "rounded-circle") :
        content_tag(:i, "", class: "bi bi-person-circle", style: "font-size: 1.3em; color: #333;")) +
        link_to(post.title, trip_path(post.trip, page: pagy_get_page_of(post, pagy), anchor: "post_#{post.id}"), data: { turbo_frame: "frame_id" }, target: "_top")
    end
  end

  private

    # Helper method to calculate the page of the post
    def pagy_get_page_of(post, pagy)
      items_per_page = pagy.limit
      post_index = post.trip.visible_posts.order(id: :desc).pluck(:id).index(post.id) + 1
      (post_index.to_f / items_per_page).ceil
    end
end
