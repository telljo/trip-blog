class Post < ApplicationRecord
  include Post::FullTextSearch

  belongs_to :trip
  belongs_to :user
  has_many :comments, class_name: "PostComment", dependent: :destroy
  has_many :likes, class_name: "UserPostLike", dependent: :destroy
  enum :travel_type, [ :train, :bus, :car, :rickshaw, :motorbike, :boat, :plane, :walking, :nina ]
  validates :title, presence: true
  validates :body, presence: true

  has_rich_text :body
  has_many_attached :attachments
  has_many :post_attachment_captions, dependent: :destroy
  accepts_nested_attributes_for :post_attachment_captions, reject_if: proc { |attributes| attributes["text"].blank? }, allow_destroy: true

  has_many :post_locations, dependent: :destroy
  accepts_nested_attributes_for :post_locations, reject_if: proc { |attributes| attributes["latitude"].blank? || attributes["longitude"].blank? }, allow_destroy: true

  before_destroy :purge_attachments

  broadcasts_refreshes_to :trip

  scope :with_location, -> { joins(:post_locations).where.not(post_locations: { latitude: nil, longitude: nil }) }

  def final_location
    post_locations.order(created_at: :desc).first
  end

  def preview_image
    attachment = attachments.find(&:image?)

    image_as_thumbnail(attachment) if attachment
  end

  def image_as_thumbnail(image)
    return unless image.content_type.in?(%w[image/jpeg image/png])

    image.variant(resize_to_limit: [ 1000, 1000 ]).processed
  end

  def liked_by?(user)
    likes.exists?(user: user)
  end

  private

  def purge_attachments
    attachments.purge_later
  end
end
