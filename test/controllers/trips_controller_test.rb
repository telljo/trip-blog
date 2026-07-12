require "test_helper"

class TripsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trip = trips(:one)
    @user = users(:lazaro_nixon)
    @storage_keys = []
  end

  teardown do
    @storage_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
  end

  test "should get index" do
    get trips_url
    assert_response :success
    assert_select ".trip-preview-card", count: 2
    assert_select ".post-preview-card", minimum: 2
  end

  test "index does not preview hidden posts" do
    hidden_post = posts(:one)
    hidden_post.update!(hidden: true)

    get trips_url

    assert_response :success
    assert_select ".post-preview-card", text: hidden_post.title, count: 0
  end

  test "index uses summary and caption alt text for post previews" do
    post = posts(:one)
    post.update!(body: "Preview opener for the card.\n\nMore detail for the full post.")
    attachment = attach_test_image(post, filename: "trip-preview.png")
    PostAttachmentCaption.create!(post: post, attachment: attachment, text: "Temple gate at sunrise")

    get trips_url

    assert_response :success
    assert_select ".post-preview-card__image[alt=?]", "Temple gate at sunrise"
    assert_select ".post-preview-card__excerpt", text: "Preview opener for the card."
  end

  test "show queues hidden post carousel images for throttled preloading" do
    post = posts(:one)
    attach_test_image(post, filename: "carousel-one.png")
    attach_test_image(post, filename: "carousel-two.png")

    get trip_url(@trip)

    assert_response :success
    assert_select ".carousel img.post-image[loading='eager']", count: 1
    assert_select ".carousel img.post-image[loading='lazy'][data-carousel-preload='true']", count: 1
    assert_select ".carousel img.post-image[fetchpriority='low']", count: 1
    assert_select ".carousel > .carousel-image-loader[aria-hidden='true']", count: 1
  end

  test "should get new" do
    sign_in_as @user

    get new_trip_url
    assert_response :success
  end

  test "should create trip" do
    sign_in_as @user

    assert_difference("Trip.count") do
      post trips_url, params: { trip: { name: "New trip", body: "New trip body" } }
    end

    assert_redirected_to trip_url(Trip.last)
  end

  test "should show trip" do
    get trip_url(@trip)
    assert_response :success
  end

  test "show uses one map controller for the post feed" do
    posts(:one).update_columns(latitude: -8.894, longitude: 116.278)

    get trip_url(@trip)

    assert_response :success
    assert_select ".trip-feed-layout[data-controller~='map']", count: 1
    assert_select ".post [data-controller~='map']", count: 0
  end

  test "show keeps pagination nav and posts list in the advancing turbo frame" do
    5.times do |index|
      @trip.posts.create!(
        title: "Pagination post #{index + 1}",
        body: "Pagination post body #{index + 1}",
        user: @user,
        created_at: (index + 1).minutes.ago
      )
    end

    get trip_url(@trip, page: 2)

    assert_response :success
    assert_select "turbo-frame#trip-posts-page[data-turbo-action='advance']"
    assert_select "turbo-frame#trip-posts-page #posts"
    assert_select "turbo-frame#trip-posts-page a.page-link[data-turbo-frame='trip-posts-page'][data-turbo-action='advance']", minimum: 2
    assert_select "turbo-frame#trip-posts-page a.page-link[aria-current='page']", text: "2"
  end

  test "trip url uses id backed slug" do
    assert_match %r{/trips/#{@trip.id}-trip-one\z}, trip_url(@trip)
  end

  test "old numeric trip url redirects to slugged url" do
    get trip_url(id: @trip.id)

    assert_redirected_to trip_url(@trip)
    assert_response :moved_permanently
  end

  test "stale trip slug redirects to current slugged url" do
    get trip_url(id: "#{@trip.id}-old-title")

    assert_redirected_to trip_url(@trip)
    assert_response :moved_permanently
  end

  test "should get edit" do
    sign_in_as @user

    get edit_trip_url(@trip)
    assert_response :success
  end

  test "should update trip" do
    sign_in_as @user

    patch trip_url(@trip), params: { trip: { name: "Updated trip" } }
    assert_redirected_to trip_url(@trip.reload)
  end

  test "should destroy trip" do
    sign_in_as @user

    assert_difference("Trip.count", -1) do
      delete trip_url(@trip)
    end

    assert_redirected_to trips_url
  end

  private

  def attach_test_image(post, filename:)
    File.open(Rails.root.join("app/assets/images/motorbike-left.png")) do |file|
      post.attachments.attach(io: file, filename: filename, content_type: "image/png")
    end

    post.attachments_attachments.order(:id).last.tap do |attachment|
      @storage_keys << attachment.blob.key
    end
  end
end
