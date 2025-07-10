module PostsHelper
  def post_link_with_image(post, pagy)
    return unless post.trip && post.id

    content_tag(:div, class: "d-flex flex-row gap-1") do
      (post.user.image_as_thumbnail.present? ?
        image_tag(post.user.image_as_thumbnail, class: "rounded-circle", style: "height: 22px; width: 22px;") :
        content_tag(:i, "", class: "bi bi-person-circle", style: "font-size: 1.3em; color: #333;")) +
        link_to(post.title, trip_path(post.trip, page: pagy_get_page_of(post, pagy), anchor: "post_#{post.id}"), data: { turbo_frame: "frame_id" }, target: "_top")
    end
  end

  def post_data(post)
    {
      postId: post.id,
      title: post.title,
      image: post.preview_image
    }.to_json
  end

  private

    # Helper method to calculate the page of the post
    def pagy_get_page_of(post, pagy)
      items_per_page = pagy.vars[:items]
      post_index = post.trip.posts.order(id: :desc).pluck(:id).index(post.id) + 1
      (post_index.to_f / items_per_page).ceil
    end
end
