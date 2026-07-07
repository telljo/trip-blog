require "test_helper"

class PostMailerTest < ActionMailer::TestCase
  test "new_post_email" do
    user = users(:lazaro_nixon)
    post = posts(:one)
    mail = PostMailer.new_post_email(user, post, trip_followers(:one))

    assert_equal "New Post on Footprints - #{post.trip.name}", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal [ "jtell1997@gmail.com" ], mail.from
    assert_match "Hello #{user.username}", mail.body.encoded
    assert_match Rails.application.routes.url_helpers.post_url(post, host: "example.com"), mail.text_part.body.decoded
  end
end
