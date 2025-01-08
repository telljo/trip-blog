class Post < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  validates :title, presence: true
  validates :body, presence: true
  # geocoded_by :address

  has_rich_text :body
  has_many_attached :images, dependent: :destroy
  # validate :image_type

  broadcasts_refreshes_to :trip

  # after_validation :geocode
  reverse_geocoded_by :latitude, :longitude do |obj, results|
    if geo = results.first
      obj.street  = geo.street_address
      obj.city    = geo.city
      obj.state = geo.state
      obj.country = geo.country_code
    else
      Rails.logger.debug "Geocoding results are empty for latitude: #{obj.latitude}, longitude: #{obj.longitude}"
    end
  end
  after_validation :reverse_geocode

  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }

  def image_as_thumbnail(image)
    return unless image.content_type.in?(%w[image/jpeg image/png])

    image.variant(resize_to_limit: [ 300, 300 ]).processed
  end

  def image_as_small(image)
    return unless image.content_type.in?(%w[image/jpeg image/png])

    image.variant(resize_to_limit: [ 150, 150 ]).processed
  end

  def address
    [ street, city, state, country ].compact.join(", ")
  end

  def short_address
    [ city, state, country ].compact.join(", ")
  end

  private

  def image_type
    images.each do |image|
      return unless image.attached?

      errors.add(:image, "is missing!") if image.attached? == false
      return if image.content_type.in?(%('image/jpeg image/png'))

      errors.add(:image, "Image must be a jpeg or png.")
    end
  end
end
