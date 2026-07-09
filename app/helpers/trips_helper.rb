require "nokogiri"

module TripsHelper
  def posts_pagination_nav(pagy)
    html = pagy.series_nav(
      :bootstrap,
      anchor_string: 'data-turbo-frame="posts"',
      aria_label: "Posts pages"
    )
    fragment = Nokogiri::HTML.fragment(html)

    fragment.css("a.page-link").each do |link|
      label = accessible_pagination_label(link)
      link["aria-label"] = label if label.present?
    end

    fragment.to_html.html_safe
  end

  def generated_points(trip, pagy)
    trip.visible_posts.with_location.order(created_at: :desc).map do |post|
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

  private
    def accessible_pagination_label(link)
      text = link.text.strip

      return "Current posts page, page #{text}" if text.match?(/\A\d+\z/) && link["aria-current"] == "page"
      return "Go to posts page #{text}" if text.match?(/\A\d+\z/)
      return "Go to previous posts page" if text == "<"
      return "Go to next posts page" if text == ">"
      return "More posts pages" if text == "..."
      return "More posts pages" if text == "…"

      nil
    end
end
