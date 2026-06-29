require "test_helper"

class TripFollowerPropagatorTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @creator = create_user("creator")
    @first_follower = create_user("first_follower")
    @second_follower = create_user("second_follower")
    @other_user = create_user("other_user")
  end

  test "copies followers from trips the creator owns or accompanies" do
    owned_trip = create_trip(user: @creator, name: "Owned trip")
    companion_trip = create_trip(user: @other_user, name: "Companion trip")
    TripCompanion.create!(trip: companion_trip, user: @creator)
    TripFollower.create!(trip: owned_trip, user: @first_follower)
    TripFollower.create!(trip: companion_trip, user: @second_follower)

    new_trip = nil
    emails = capture_emails do
      new_trip = create_trip(user: @creator, name: "New trip")
    end

    assert_equal [ @first_follower.id, @second_follower.id ], new_trip.followers.order(:user_id).pluck(:user_id)
    assert_equal [ @first_follower.email, @second_follower.email ], emails.flat_map(&:to).sort
  end

  test "subscribes and emails a follower only once when they follow multiple source trips" do
    first_trip = create_trip(user: @creator, name: "First trip")
    second_trip = create_trip(user: @creator, name: "Second trip")
    TripFollower.create!(trip: first_trip, user: @first_follower)
    TripFollower.create!(trip: second_trip, user: @first_follower)

    assert_enqueued_emails 1 do
      new_trip = create_trip(user: @creator, name: "New trip")

      assert_equal 1, new_trip.followers.where(user: @first_follower).count
    end
  end

  test "does not copy followers from unrelated users trips" do
    unrelated_trip = create_trip(user: @other_user, name: "Unrelated trip")
    TripFollower.create!(trip: unrelated_trip, user: @first_follower)

    assert_no_emails do
      new_trip = create_trip(user: @creator, name: "New trip")

      assert_empty new_trip.followers
    end
  end

  test "does not subscribe the creator" do
    existing_trip = create_trip(user: @creator, name: "Existing trip")
    TripFollower.create!(trip: existing_trip, user: @creator)

    assert_no_emails do
      new_trip = create_trip(user: @creator, name: "New trip")

      assert_not new_trip.followed_by?(@creator)
    end
  end

  test "does not send emails when there are no existing followers" do
    assert_no_emails do
      create_trip(user: @creator, name: "New trip")
    end
  end

  private

  def create_user(username)
    User.create!(
      username: username,
      email: "#{username}@example.com",
      password: "Secret1*3*5*"
    )
  end

  def create_trip(user:, name:)
    Trip.create!(user: user, name: name, body: "Trip body")
  end
end
