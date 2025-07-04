class Post < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  has_many :comments, class_name: "PostComment", dependent: :destroy
  has_many :likes, class_name: "UserPostLike", dependent: :destroy
  enum :travel_type, [ :train, :bus, :car, :rickshaw, :motorbike, :boat, :plane, :walk ]
  validates :title, presence: true
  validates :body, presence: true

  has_rich_text :body
  has_many_attached :attachments
  has_many :post_attachment_captions, dependent: :destroy
  accepts_nested_attributes_for :post_attachment_captions, reject_if: proc { |attributes| attributes["text"].blank? }, allow_destroy: true

  before_destroy :purge_attachments

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

  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }

  def preview_image
    attachment = attachments.find(&:image?)

    image_as_thumbnail(attachment) if attachment
  end

  def image_as_thumbnail(image)
    return unless image.content_type.in?(%w[image/jpeg image/png])

    image.variant(resize_to_limit: [ 1000, 1000 ]).processed
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

  private

  def purge_attachments
    attachments.purge_later
  end
end
