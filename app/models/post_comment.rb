class PostComment < ApplicationRecord
  belongs_to :post
  belongs_to :user
  has_one :trip, through: :post
  has_many :likes, class_name: "PostCommentLike", dependent: :destroy

  broadcasts_refreshes_to :post

  validates :content, presence: true

  def liked_by?(user)
    likes.exists?(user: user)
  end
end
