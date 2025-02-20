class PostCommentLikesController < ApplicationController
  before_action :set_post_comment_like, only: %i[destroy]
  before_action :set_post_comment, only: %i[create destroy]

  def create
    @post_comment_like = @post_comment.likes.new(user: Current.user)

    respond_to do |format|
      if @post_comment_like.save
        format.html do
          redirect_to @post_comment.trip
        end
      else
        format.html { render @post_comment.trip, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @post_comment_like.destroy

    respond_to do |format|
      format.html do
        redirect_to @post_comment.trip
      end
    end
  end

  private

  def set_post_comment_like
    @post_comment_like = PostCommentLike.find(params.expect(:id))
  end

  def set_post_comment
    @post_comment = PostComment.find(params[:post_comment_id])
  end
end
