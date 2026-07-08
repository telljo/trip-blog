class ProcessPostImageVariantJob < ApplicationJob
  queue_as :images

  discard_on ActiveRecord::RecordNotFound

  def perform(attachment_id)
    attachment = ActiveStorage::Attachment.find(attachment_id)
    return unless attachment.record_type == "Post" && attachment.name == "attachments" && attachment.blob.image?

    attachment.variant(:feed).processed
    attachment.variant(:feed_preview).processed
  end
end
