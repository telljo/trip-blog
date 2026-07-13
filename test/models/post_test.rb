require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @storage_keys = []
  end

  teardown do
    @storage_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
  end

  test "feed attachment variants are configured" do
    variants = Post.attachment_reflections.fetch("attachments").named_variants

    assert_equal(
      { resize_to_limit: [ 800, 800 ], format: :webp, saver: { quality: 82 } },
      variants.fetch(:feed).transformations
    )
    assert_equal(
      { resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 82 } },
      variants.fetch(:feed_preview).transformations
    )
  end

  test "feed attachment variants process as webp files" do
    attachment = attach_test_image(posts(:one))
    variant = attachment.variant(:feed_preview).processed
    @storage_keys << variant.key

    data = variant.download

    assert_equal "image/webp", variant.content_type
    assert_equal "RIFF", data.byteslice(0, 4)
    assert_equal "WEBP", data.byteslice(8, 4)
    assert_equal "post-test.webp", variant.filename.to_s
  end

  test "feed image methods use the original until background variants are processed" do
    post = posts(:one)
    attachment = attach_test_image(post)

    assert_equal attachment, post.image_as_feed(attachment)
    assert_equal attachment, post.image_as_feed_preview(attachment)
  end

  test "feed image methods use processed background variants when available" do
    post = posts(:one)
    attachment = attach_test_image(post)
    feed = attachment.variant(:feed).processed
    preview = attachment.variant(:feed_preview).processed
    @storage_keys.concat([ feed.key, preview.key ])

    assert_equal feed.key, post.image_as_feed(attachment).key
    assert_equal preview.key, post.image_as_feed_preview(attachment).key
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
