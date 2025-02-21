class PostCommentReply < ApplicationRecord
  belongs_to :post_comment
  belongs_to :user
  has_one :post, through: :post_comment
  has_one :trip, through: :post

  validates :content, presence: true
end
