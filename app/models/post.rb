class Post < ApplicationRecord
  belongs_to :trip
  has_one :user, through: :trip
  validates :title, presence: true
  validates :body, presence: true
  # geocoded_by :address

  has_rich_text :body
  has_one_attached :image, dependent: :destroy
  validate :image_type

  broadcasts_refreshes_to :trip

  attr_accessor :remove_image

  after_save :purge_image, if: :remove_image

  # after_validation :geocode
  reverse_geocoded_by :latitude, :longitude do |obj, results|
    if geo = results.first
      obj.street  = geo.street_address
      obj.city    = geo.city
      obj.state = geo.state
      obj.country = geo.country_code
    end
  end
  after_validation :reverse_geocode

  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }

  def image_as_thumbnail
    return unless image.content_type.in?(%w[image/jpeg image/png])

    image.variant(resize_to_limit: [ 300, 300 ]).processed
  end

  def address
    [ street, city, state, country ].compact.join(", ")
  end

  def short_address
    [ city, state, country ].compact.join(", ")
  end

  private

  def purge_image
    image.purge_later
  end

  def image_type
    return unless image.attached?

    errors.add(:image, "is missing!") if image.attached? == false
    return if image.content_type.in?(%('image/jpeg image/png'))

    errors.add(:image, "Image must be a jpeg or png.")
  end
end
