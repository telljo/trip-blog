require "test_helper"

class TripFollowerControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trip = trips(:one)
    @user = User.create!(
      username: "new_follower",
      email: "new_follower@example.com",
      password: "Secret1*3*5*"
    )
  end

  test "following a trip redirects Turbo requests to the HTML trip page" do
    sign_in_as @user
    headers = { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_difference("TripFollower.count") do
      post trip_trip_followers_url(@trip), headers: headers
    end

    assert_response :redirect

    follow_redirect!(headers: headers)

    assert_response :success
    assert_equal "text/html", response.media_type
  end
end
