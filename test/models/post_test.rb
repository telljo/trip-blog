require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "display attachment variant is configured" do
    variant = Post.attachment_reflections.fetch("attachments").named_variants.fetch(:display)

    assert_equal({ resize_to_limit: [ 1000, 1000 ] }, variant.transformations)
  end

  test "active storage image jobs use the images queue" do
    queues = Rails.application.config.active_storage.queues

    assert_equal :images, queues.analysis
    assert_equal :images, queues.transform
  end
end
