module ApplicationHelper
  def tiny_avatar_image_tag(user, size: 24, **options)
    return unless user&.profile_picture&.attached?

    avatar = user.image_as_tiny_avatar
    return unless avatar

    image_tag(
      avatar,
      {
        alt: "",
        class: "rounded-circle",
        width: size,
        height: size
      }.merge(options)
    )
  end

  def post_feed_image_tag(post, attachment, **options)
    width, height = post.image_display_dimensions(attachment)
    preview = post.image_as_feed_preview(attachment)
    full = post.image_as_feed(attachment)
    return unless preview && full

    image_tag(
      preview,
      {
        alt: post.image_alt_text(attachment),
        class: "post-image",
        height: height,
        loading: "lazy",
        sizes: "(max-width: 999px) 300px, 400px",
        srcset: "#{url_for(preview)} 400w, #{url_for(full)} 800w",
        width: width
      }.merge(options)
    )
  end

  def post_feed_image_link(post, attachment, **options)
    image = post_feed_image_tag(post, attachment, **options)
    full = post.image_as_feed(attachment)
    return unless image && full

    link_to image, full, target: "_blank"
  end

  def carousel_image_loading_options(index)
    if index.zero?
      { decoding: "async", loading: "eager" }
    else
      {
        data: { carousel_preload: true },
        decoding: "async",
        fetchpriority: "low",
        loading: "lazy"
      }
    end
  end

  def time_ago_in_words_with_units(from_time)
    distance_in_seconds = ((Time.current - from_time) / 1.second).round
    case distance_in_seconds
    when 0..59
      "#{distance_in_seconds}s"
    when 59..3599
      "#{(distance_in_seconds / 60).round}m"
    when 3600..86399
      "#{(distance_in_seconds / 3600).round}h"
    when 86400..604799
      "#{(distance_in_seconds / 86400).round}d"
    when 604800..2678399
      "#{(distance_in_seconds / 604800).round}w"
    when 2678400..31556951
      "#{(distance_in_seconds / 2678400).round}mo"
    else
      "#{(distance_in_seconds / 31556952).round}y"
    end
  end
end
