require "test_helper"

class TripMailerTest < ActionMailer::TestCase
  test "new trip subscription email explains the subscription and how to unfollow" do
    trip = trips(:one)
    follower = User.create!(
      username: "trip_follower",
      email: "trip_follower@example.com",
      password: "Secret1*3*5*"
    )
    trip_follower = TripFollower.create!(trip: trip, user: follower)

    mail = TripMailer.new_trip_subscription_email(trip_follower)

    assert_equal "A new Footprints trip from #{trip.user.username} - #{trip.name}", mail.subject
    assert_equal [ follower.email ], mail.to
    assert_equal [ "jtell1997@gmail.com" ], mail.from
    assert_match "automatically subscribed", mail.html_part.body.encoded
    assert_match "Unfollow", mail.html_part.body.encoded
    assert_match Rails.application.routes.url_helpers.trip_url(trip, host: "example.com"), mail.html_part.body.encoded
  end
end
