class PostComment < ApplicationRecord
  belongs_to :post
  belongs_to :user

  broadcasts_refreshes_to :post

  validates :content, presence: true
end