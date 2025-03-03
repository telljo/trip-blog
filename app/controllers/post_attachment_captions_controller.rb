class PostAttachmentCaptionsController < ApplicationController
  before_action :set_post_attachment_caption, only: %i[remove_attachment_caption]

  def remove_attachment_caption
    @post_attachment_caption.destroy

    redirect_to edit_post_url(@post_attachment_caption.post)
  end

  private

  def set_post_attachment_caption
    @post_attachment_caption = PostAttachmentCaption.find_by(attachment_id: params[:attachment_id], post_id: params[:post_id])
  end
end
