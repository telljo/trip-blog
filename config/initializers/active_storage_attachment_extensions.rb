Rails.application.config.to_prepare do
  ActiveStorage::Attachment.class_eval do
    has_many :captions, class_name: "PostAttachmentCaption", foreign_key: :attachment_id, dependent: :destroy

    def caption?
      captions.any?
    end
  end
end
