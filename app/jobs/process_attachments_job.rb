# app/jobs/process_attachments_job.rb
require "base64"

class ProcessAttachmentsJob < ApplicationJob
  queue_as :default

  def perform(post_id, attachments)
    post = Post.find(post_id)
    attachments.each do |attachment|
      decoded_content = Base64.decode64(attachment[:content])
      post.attachments.attach(io: StringIO.new(decoded_content), filename: attachment[:filename], content_type: attachment[:content_type])
    end
  end
end
