class PostCommentsController < ApplicationController
  before_action :set_post_comment, only: %i[show edit update destroy]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :set_trip, only: %i[show edit update destroy]

  # GET /posts
  def index
    @post_comments = @post.comments
  end

  # GET /posts/1
  def show
  end

  # GET /posts/new
  def new
    @post = Post.find(params[:post_id])
    @post_comment = @post.comments.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  def create
    @post = Post.find(params[:post_id])
    @post_comment = @post.comments.new(post_comment_params)
    @post_comment.user = Current.user

    respond_to do |format|
      if @post_comment.save
        format.html do
          flash[:notice] = "Comment was successfully created."
          redirect_to @trip
        end
        format.turbo_stream { flash.now[:notice] = "Comment was successfully created." }
      else
        format.html { render @trip, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  def update
    if @post_comment.update(post_comment_params)
      flash[:notice] = "Comment was successfully updated."
      redirect_to @trip
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  def destroy
    @post_comment.destroy

    respond_to do |format|
      format.html { redirect_to post_url(@post), notice: "Comment was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Comment was successfully deleted." }
    end
  end

  private

  def set_post_comment
    @post_comment = PostComment.find(params.expect(:id))
  end

  def set_post
    @post = Post.find(@post_comment.post_id)
  end

  def set_trip
    @trip = @post.trip
  end

  # Only allow a list of trusted parameters through.
  def post_comment_params
    params.require(:post_comment).permit(:content, :like_count, :post_id)
  end
end
