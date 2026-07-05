require "test_helper"

class ProcessPostImageVariantJobTest < ActiveJob::TestCase
  setup do
    @post = posts(:one)
  end

  test "new post images enqueue display variant preprocessing" do
    assert_enqueued_with(job: ProcessPostImageVariantJob, queue: "images") do
      @post.attachments.attach(
        io: StringIO.new("image"),
        filename: "photo.jpg",
        content_type: "image/jpeg",
        identify: false
      )
    end
  end

  test "new post videos do not enqueue display variant preprocessing" do
    assert_no_enqueued_jobs only: ProcessPostImageVariantJob do
      @post.attachments.attach(
        io: StringIO.new("video"),
        filename: "clip.mp4",
        content_type: "video/mp4",
        identify: false
      )
    end
  end
end
