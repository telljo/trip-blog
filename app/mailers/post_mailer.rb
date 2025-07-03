class PostMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def new_post_email(user, post, follower)
    @user = user
    @post = post

    mail(
      to: @user.email,
      subject: "New Post on Footprints - #{@post.trip.name}"
    )
  end

  def draft_post_email(user, post)
    @user = user
    @post = post

    mail(
      to: @user.email,
      subject: "A draft Post on Footprints was published - #{@post.trip.name}"
    )
  end
end
