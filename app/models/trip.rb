class Trip < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :body, presence: true
  has_many :posts, dependent: :destroy
  has_many :post_locations, through: :posts
  has_many :companions, class_name: "TripCompanion", dependent: :destroy
  has_many :followers, class_name: "TripFollower", dependent: :destroy
  has_many :users, through: :companions
  accepts_nested_attributes_for :companions, allow_destroy: true
  after_update_commit :broadcast_companions
  has_rich_text :body

  has_many :administrators, -> { joins(:trip_companions) }
  has_many :visible_posts, -> { where(hidden: false) }, class_name: "Post"

  broadcasts_refreshes

  def followed_by?(user)
    followers.exists?(user: user)
  end

  def countries
    posts.with_location.pluck(:country).uniq.compact.sort
  end

  private

  def broadcast_companions
    companions.each do |companion|
      broadcast_replace_to companion
    end
  end
end
