require "test_helper"

class PostMailerTest < ActionMailer::TestCase
  test "new_post_email" do
    mail = PostMailer.new_post_email
    assert_equal "New post email", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
