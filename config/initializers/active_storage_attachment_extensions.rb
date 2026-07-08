module ActiveStorageAttachmentExtensions
  extend ActiveSupport::Concern

  included do
    has_one :caption, class_name: "PostAttachmentCaption", foreign_key: :attachment_id, dependent: :destroy
    accepts_nested_attributes_for :caption, allow_destroy: true
    after_create_commit :preprocess_post_feed_variants
  end

  def caption?
    caption.present?
  end

  private

  def preprocess_post_feed_variants
    return unless record_type == "Post" && name == "attachments" && blob.image?

    ProcessPostImageVariantJob.perform_later(id)
  end
end

Rails.application.config.to_prepare do
  unless ActiveStorage::Attachment.include?(ActiveStorageAttachmentExtensions)
    ActiveStorage::Attachment.include(ActiveStorageAttachmentExtensions)
  end
end
