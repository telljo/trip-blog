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

  test "public index excludes hidden and draft posts" do
    @post.update!(hidden: true)
    posts(:two).update!(draft: true)

    get posts_url

    assert_response :success
    assert_select ".post", text: /#{Regexp.escape(@post.title)}/, count: 0
    assert_select ".post", text: /#{Regexp.escape(posts(:two).title)}/, count: 0
  end

  test "logged in user index includes private posts they manage" do
    @post.update!(hidden: true, draft: true)
    sign_in_as @user

    get posts_url

    assert_response :success
    assert_select ".post", text: /#{Regexp.escape(@post.title)}/
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

  test "show includes post seo metadata" do
    attachment = attach_test_image(@post, filename: "seo-image.png")
    PostAttachmentCaption.create!(post: @post, attachment: attachment, text: "Lanterns glowing at dusk")

    get post_url(@post)

    assert_response :success
    assert_select "title", "#{@post.title} · Footprints"
    assert_select "meta[name='description'][content=?]", @post.summary(length: 160)
    assert_select "link[rel='canonical'][href=?]", post_url(@post)
    assert_select "meta[property='og:type'][content='article']"
    assert_select "h1", text: @post.title
    assert_select "img.post-image[alt=?]", "Lanterns glowing at dusk"

    blog_post = json_ld_entity("BlogPosting")
    assert_equal @post.title, blog_post["headline"]
    assert_equal post_url(@post), blog_post["url"]
    assert_equal @post.trip.name, blog_post.dig("isPartOf", "name")
    assert_equal "Lanterns glowing at dusk", blog_post.dig("image", 0, "caption")

    breadcrumb = json_ld_entity("BreadcrumbList")
    assert_equal [ "Home", @post.trip.name, @post.title ], breadcrumb["itemListElement"].map { |item| item["name"] }
    assert_equal post_url(@post), breadcrumb.dig("itemListElement", 2, "item")
  end

  test "show meta description uses first paragraph as summary" do
    @post.update!(body: "A compact opening summary.\n\nA much longer second paragraph with more travel detail.")

    get post_url(@post)

    assert_response :success
    assert_select "meta[name='description'][content=?]", "A compact opening summary."
    assert_select ".post-preview", text: "A compact opening summary."
  end

  test "post url uses id backed slug" do
    assert_match %r{/posts/#{@post.id}-post-one\z}, post_url(@post)
  end

  test "old numeric post url redirects to slugged url" do
    get post_url(id: @post.id)

    assert_redirected_to post_url(@post)
    assert_response :moved_permanently
  end

  test "stale post slug redirects to current slugged url" do
    get post_url(id: "#{@post.id}-old-title")

    assert_redirected_to post_url(@post)
    assert_response :moved_permanently
  end

  test "nested numeric post url redirects to standalone slugged url" do
    get trip_post_url(trip_id: @trip.id, id: @post.id)

    assert_redirected_to post_url(@post)
    assert_response :moved_permanently
  end

  test "nested post url does not resolve under a different trip" do
    get trip_post_url(trips(:two), @post)

    assert_response :not_found
  end

  test "public cannot show hidden post" do
    @post.update!(hidden: true)

    get post_url(@post)

    assert_response :not_found
  end

  test "public cannot show draft post" do
    @post.update!(draft: true)

    get post_url(@post)

    assert_response :not_found
  end

  test "owner can show hidden draft post" do
    @post.update!(hidden: true, draft: true)
    sign_in_as @user

    get post_url(@post)

    assert_response :success
  end

  test "owner numeric hidden draft post redirects to slugged url" do
    @post.update!(hidden: true, draft: true)
    sign_in_as @user

    get post_url(id: @post.id)

    assert_redirected_to post_url(@post)
    assert_response :moved_permanently
  end

  test "should get edit" do
    attach_test_image(@post, filename: "edit-carousel.png")
    sign_in_as @user

    get edit_post_url(@post)
    assert_response :success
    assert_select ".carousel > .carousel-image-loader[aria-hidden='true']", count: 1
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
    variants = [ attachment.variant(:feed).processed, attachment.variant(:feed_preview).processed ]
    variants.each { |variant| remember_storage_key(variant.key) }
    blob_id = attachment.blob_id

    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) do
      delete post_url(@post)
    end

    assert_not Post.exists?(@post.id)
    assert_not PostAttachmentCaption.exists?(caption.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
    assert_not ActiveStorage::Blob.service.exist?(attachment.blob.key)
    variants.each { |variant| assert_not ActiveStorage::Blob.service.exist?(variant.key) }
  end

  test "removing an image purges image, variant, and caption" do
    sign_in_as @user
    attachment = attach_test_image(@post, filename: "attachment-delete.png")
    caption = PostAttachmentCaption.create!(post: @post, attachment: attachment, text: "Caption")
    variants = [ attachment.variant(:feed).processed, attachment.variant(:feed_preview).processed ]
    variants.each { |variant| remember_storage_key(variant.key) }
    blob_id = attachment.blob_id
    original_key = attachment.blob.key
    variant_keys = variants.map(&:key)

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
    variant_keys.each { |variant_key| assert_not ActiveStorage::Blob.service.exist?(variant_key) }
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

  def json_ld_entity(type)
    json_ld = JSON.parse(css_select("script[type='application/ld+json']").first.text)
    json_ld.fetch("@graph").find { |entity| entity["@type"] == type }
  end
end
