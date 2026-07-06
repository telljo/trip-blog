require "test_helper"

class TripsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trip = trips(:one)
    @user = users(:lazaro_nixon)
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

  test "should get edit" do
    sign_in_as @user

    get edit_trip_url(@trip)
    assert_response :success
  end

  test "should update trip" do
    sign_in_as @user

    patch trip_url(@trip), params: { trip: { name: "Updated trip" } }
    assert_redirected_to trip_url(@trip)
  end

  test "should destroy trip" do
    sign_in_as @user

    assert_difference("Trip.count", -1) do
      delete trip_url(@trip)
    end

    assert_redirected_to trips_url
  end
end
