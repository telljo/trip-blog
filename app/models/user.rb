class User < ApplicationRecord
  scope :not_current, -> { where.not(id: Current.user) }
  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end
  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  has_many :sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 8 }

  normalizes :email, with: -> { _1.strip.downcase }

  has_one_attached :profile_picture, dependent: :destroy

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  # Trips created by the user
  has_many :trips, dependent: :destroy
  has_many :posts, through: :trips

  # Trips where the user is a companion
  has_many :trip_companions, dependent: :destroy
  has_many :companion_trips, through: :trip_companions, source: :trip
  has_many :companion_posts, through: :companion_trips, source: :posts

  def image_as_thumbnail
    return unless profile_picture.content_type.in?(%w[image/jpeg image/png])

    profile_picture.variant(resize_to_limit: [ 200, 200 ]).processed
  end
end
