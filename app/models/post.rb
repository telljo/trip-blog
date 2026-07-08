class Post < ApplicationRecord
  include Post::FullTextSearch

  attribute :travel_type, :integer

  belongs_to :trip
  belongs_to :user
  has_many :comments, class_name: "PostComment", dependent: :destroy
  has_many :likes, class_name: "UserPostLike", dependent: :destroy
  enum :travel_type, [ :train, :bus, :car, :rickshaw, :motorbike, :boat, :plane, :walking, :nina ]
  validates :title, presence: true
  validates :body, presence: true

  has_rich_text :body
  has_many_attached :attachments, dependent: :purge_later do |attachable|
    attachable.variant :feed, resize_to_limit: [ 800, 800 ], format: :webp, saver: { quality: 82 }
    attachable.variant :feed_preview, resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 82 }
  end
  has_many :post_attachment_captions, dependent: :destroy
  accepts_nested_attributes_for :post_attachment_captions, reject_if: proc { |attributes| attributes["text"].blank? }, allow_destroy: true

  broadcasts_refreshes_to :trip

  reverse_geocoded_by :latitude, :longitude do |obj, results|
    if geo = results.first
      obj.street  = geo.street_address
      obj.city    = geo.city
      obj.state = geo.state
      obj.country = geo.country
    else
      Rails.logger.debug "Geocoding results are empty for latitude: #{obj.latitude}, longitude: #{obj.longitude}"
    end
  end
  after_validation :reverse_geocode

  scope :published, -> { where(draft: false, hidden: false) }
  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }

  def self.visible_to(user)
    return published unless user

    posts = left_joins(trip: :companions)
    posts
      .where(draft: false, hidden: false)
      .or(posts.where(trips: { user_id: user.id }))
      .or(posts.where(trip_companions: { user_id: user.id }))
      .distinct
  end

  def to_param
    return unless id

    "#{id}-#{title.to_s.parameterize}"
  end

  def plain_text_body
    body.to_plain_text.to_s.squish
  end

  def summary(length: 160)
    first_paragraph = body.to_plain_text.to_s.split(/\R{2,}/).map(&:squish).find(&:present?)
    (first_paragraph.presence || plain_text_body).truncate(length)
  end

  def image_attachments
    attachments.select { |attachment| attachment.image? && image_as_thumbnail(attachment).present? }
  end

  def preview_image_attachment
    image_attachments.first
  end

  def preview_image
    attachment = preview_image_attachment

    image_as_feed(attachment) if attachment
  end

  def image_alt_text(attachment)
    caption = attachment.caption&.text.to_s.squish
    return caption if caption.present?

    location = short_address.presence
    [ "Photo from #{title}", location ].compact.join(" in ")
  end

  def image_as_thumbnail(image)
    image_as_feed_preview(image)
  end

  def image_as_feed(image)
    return unless image.content_type.in?(%w[image/jpeg image/png image/webp])

    image.variant(:feed)
  end

  def image_as_feed_preview(image)
    return unless image.content_type.in?(%w[image/jpeg image/png image/webp])

    image.variant(:feed_preview)
  end

  def image_display_dimensions(image, max_dimension: 400)
    metadata = image.blob.metadata
    width = metadata["width"].to_f
    height = metadata["height"].to_f

    return [ max_dimension, max_dimension ] unless width.positive? && height.positive?

    scale = [ max_dimension / width, max_dimension / height, 1 ].min
    [ (width * scale).round, (height * scale).round ]
  end

  def image_as_display(image)
    return unless image.content_type.in?(%w[image/jpeg image/png])

    image_as_feed_preview(image)
  end

  def address
    [ street, city, state, country ].compact.join(", ")
  end

  def short_address
    [ city, state, country ].compact.join(", ")
  end

  def liked_by?(user)
    likes.exists?(user: user)
  end
end
