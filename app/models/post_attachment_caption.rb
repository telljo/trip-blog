class PostAttachmentCaption < ApplicationRecord
  belongs_to :post
  belongs_to :attachment, class_name: "ActiveStorage::Attachment"

  validates :text, presence: true, length: { maximum: 50 }
end
