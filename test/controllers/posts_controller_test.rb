require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @post = posts(:one)
    @trip = trips(:one)
    @user = users(:lazaro_nixon)
    @storage_keys = []
  end

  teardown do
    @storage_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get new" do
    sign_in_as @user

    get new_trip_post_url(@trip)
    assert_response :success
    assert_select "form[data-controller='direct-uploads'][data-direct-uploads-concurrency-value='3']"
    assert_select "input[type='file'][data-action='change->direct-uploads#upload'][data-direct-upload-url]"
  end

  test "should create post" do
    sign_in_as @user

    assert_difference("Post.count") do
      post trip_posts_url(@trip), params: { post: { title: "New post", body: "New post body" } }
    end

    assert_redirected_to trip_url(@trip)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    sign_in_as @user

    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    sign_in_as @user

    patch post_url(@post), params: { post: { title: "Updated post" } }
    assert_redirected_to trip_url(@post.trip)
  end

  test "should destroy post" do
    sign_in_as @user

    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to trip_url(@post.trip)
  end

  test "destroying post purges image, variant, and caption" do
    sign_in_as @user
    attachment = attach_test_image(@post, filename: "post-delete.png")
    caption = PostAttachmentCaption.create!(post: @post, attachment: attachment, text: "Caption")
    variant = attachment.variant(:display).processed
    remember_storage_key(variant.key)
    blob_id = attachment.blob_id

    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) do
      delete post_url(@post)
    end

    assert_not Post.exists?(@post.id)
    assert_not PostAttachmentCaption.exists?(caption.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
    assert_not ActiveStorage::Blob.service.exist?(attachment.blob.key)
    assert_not ActiveStorage::Blob.service.exist?(variant.key)
  end

  test "removing an image purges image, variant, and caption" do
    sign_in_as @user
    attachment = attach_test_image(@post, filename: "attachment-delete.png")
    caption = PostAttachmentCaption.create!(post: @post, attachment: attachment, text: "Caption")
    variant = attachment.variant(:display).processed
    remember_storage_key(variant.key)
    blob_id = attachment.blob_id
    original_key = attachment.blob.key
    variant_key = variant.key

    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) do
      delete remove_attachment_trip_post_url(
        @trip,
        @post,
        attachment_id: attachment.id
      )
    end

    assert_redirected_to edit_post_url(@post)
    assert_not PostAttachmentCaption.exists?(caption.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
    assert_not ActiveStorage::Blob.service.exist?(original_key)
    assert_not ActiveStorage::Blob.service.exist?(variant_key)
  end

  test "user cannot remove another user's attachment" do
    attachment = attach_test_image(@post, filename: "unauthorized-delete.png")
    another_user = User.create!(
      email: "another-user@example.com",
      username: "another-user",
      password: "Secret1*3*5*"
    )
    sign_in_as another_user

    assert_no_difference -> { ActiveStorage::Attachment.count } do
      delete remove_attachment_trip_post_url(
        @trip,
        @post,
        attachment_id: attachment.id
      )
    end

    assert_redirected_to trips_url
    assert ActiveStorage::Attachment.exists?(attachment.id)
    assert ActiveStorage::Blob.service.exist?(attachment.blob.key)
  end

  test "attachment removal is scoped to the post" do
    attachment = attach_test_image(posts(:two), filename: "wrong-post-delete.png")
    sign_in_as @user

    delete remove_attachment_trip_post_url(
      @trip,
      @post,
      attachment_id: attachment.id
    )

    assert_response :not_found
    assert ActiveStorage::Attachment.exists?(attachment.id)
    assert ActiveStorage::Blob.service.exist?(attachment.blob.key)
  end

  private

  def attach_test_image(post, filename:)
    File.open(Rails.root.join("app/assets/images/motorbike-left.png")) do |file|
      post.attachments.attach(io: file, filename: filename, content_type: "image/png")
    end

    post.attachments_attachments.order(:id).last.tap do |attachment|
      remember_storage_key(attachment.blob.key)
    end
  end

  def remember_storage_key(key)
    @storage_keys << key
  end
end
