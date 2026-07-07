require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @storage_keys = []
  end

  teardown do
    @storage_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
  end

  test "display attachment variant is configured" do
    variant = Post.attachment_reflections.fetch("attachments").named_variants.fetch(:display)

    assert_equal({ resize_to_limit: [ 1000, 1000 ] }, variant.transformations)
  end

  test "active storage image jobs use the images queue" do
    queues = Rails.application.config.active_storage.queues

    assert_equal :images, queues.analysis
    assert_equal :images, queues.transform
  end

  test "summary uses the first paragraph" do
    post = posts(:one)
    post.update!(body: "Opening summary for search snippets.\n\nMore detailed travel notes.")

    assert_equal "Opening summary for search snippets.", post.summary
  end

  test "image alt text prefers caption" do
    post = posts(:one)
    attachment = attach_test_image(post)
    PostAttachmentCaption.create!(post: post, attachment: attachment, text: "Lanterns glowing at dusk")

    assert_equal "Lanterns glowing at dusk", post.image_alt_text(attachment)
  end

  test "image alt text falls back to post title and location" do
    post = posts(:one)
    post.update!(city: "Kyoto", country: "Japan")
    attachment = attach_test_image(post)

    assert_equal "Photo from Post one in Kyoto, Japan", post.image_alt_text(attachment)
  end

  private

  def attach_test_image(post)
    File.open(Rails.root.join("app/assets/images/motorbike-left.png")) do |file|
      post.attachments.attach(io: file, filename: "post-test.png", content_type: "image/png")
    end

    post.attachments_attachments.order(:id).last
      .tap { |attachment| @storage_keys << attachment.blob.key }
  end
end
