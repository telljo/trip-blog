module PostNotifier
  extend ActiveSupport::Concern

  included do
    after_action :notify_followers, only: %i[create]
  end

  private

  def notify_followers
    if @post.persisted?

      @post.trip.followers.each do |follower|
        user = follower.user
        next if user == Current.user

        PostMailer.new_post_email(user, @post).deliver_later
      end
    end
  end
end
