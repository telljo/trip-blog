class UserPostLikesController < ApplicationController
  before_action :set_user_post_like, only: %i[destroy]
  before_action :set_post, only: %i[create destroy]

  # POST /posts
  def create
    @user_post_like = @post.likes.new(user: Current.user)

    respond_to do |format|
      if @user_post_like.save
        format.html do
          redirect_to @post.trip
        end
      else
        format.html { render @post.trip, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user_post_like.destroy

    respond_to do |format|
      format.html do
        redirect_to @post.trip
      end
    end
  end

  private

  def set_user_post_like
    @user_post_like = UserPostLike.find(params.expect(:id))
  end

  def set_post
    @post = Post.find(params[:post_id])
  end
end
