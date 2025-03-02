Rails.application.config.to_prepare do
  ActiveStorage::Attachment.class_eval do
    has_one :caption, class_name: "PostAttachmentCaption", foreign_key: :attachment_id, dependent: :destroy
    accepts_nested_attributes_for :caption, allow_destroy: true

    def caption?
      caption.present?
    end
  end
end
