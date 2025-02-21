class PostCommentRepliesController < ApplicationController
  before_action :set_post_comment_reply, only: %i[show edit update destroy]
  before_action :set_post_comment, only: %i[show edit update destroy]
  before_action :set_trip, only: %i[show edit update destroy]

  def index
    @post_comment_replies = @post_comment.replies
  end

  def new
    @post_comment = PostCommet.find(params[:post_comment_id])
    @post_comment_reply = @post_comment.replies.new
  end

  def create
    @post_comment = PostComment.find(params[:post_comment_id])
    @post_comment_reply = @post_comment.replies.new(post_comment_reply_params)
    @post_comment_reply.user = Current.user

    respond_to do |format|
      if @post_comment_reply.save
        format.html do
          flash[:notice] = "Reply was successfully created."
          redirect_to @post_comment_reply.trip
        end
        format.turbo_stream { flash.now[:notice] = "Reply was successfully created." }
      else
        format.html { render @post_comment_reply.trip, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @post_comment_reply.update(post_comment_reply_params)
      flash[:notice] = "Reply was successfully updated."
      redirect_to @post_comment_reply.trip
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post_comment_reply.destroy

    respond_to do |format|
      format.html { redirect_to trip_url(@post_comment_reply.trip), notice: "Reply was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Reply was successfully deleted." }
    end
  end

  private

  def set_post_comment_reply
    @post_comment_reply = PostCommentReply.find(params.expect(:id))
  end

  def set_post_comment
    @post_comment = PostComment.find(params[:post_comment_id])
  end

  # Only allow a list of trusted parameters through.
  def post_comment_reply_params
    params.require(:post_comment_reply).permit(:content, :post_comment_id)
  end
end
