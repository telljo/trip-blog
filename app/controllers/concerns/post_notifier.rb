module PostNotifier
  extend ActiveSupport::Concern

  included do
    after_action :notify_create, only: %i[create]
    after_action :notify_draft_if_published, only: %i[update]
  end

  private

  def notify_create
    if @post.persisted? && !@post.draft? && !@post.notified_at?

      @post.update(notified_at: Time.current)
      @post.trip.followers.each do |follower|
        user = follower.user
        next if user == Current.user

        PostMailer.new_post_email(user, @post, follower).deliver_later(wait_until: 1.minutes.from_now)
      end
    end
  end

  def notify_draft_if_published
    if @post.saved_change_to_draft?(from: true, to: false) && @post.persisted? && !@post.notified_at?

      @post.update(notified_at: Time.current)
      @post.trip.followers.each do |follower|
        user = follower.user
        next if user == Current.user

        PostMailer.draft_post_email(user, @post, follower).deliver_later(wait_until: 1.minutes.from_now)
      end
    end
  end
end
