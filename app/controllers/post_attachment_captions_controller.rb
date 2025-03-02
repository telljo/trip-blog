class PostAttachmentCaptionsController < ApplicationController
  before_action :set_post_attachment_caption, only: %i[show edit update destroy]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :set_trip, only: %i[show edit update destroy]

  # GET /posts/1
  def show
  end

  # GET /posts/new
  def new
    @post = Post.find(params[:post_id])
    @post_attachment_caption = @post.comments.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  def create
    @post = Post.find(params[:post_id])
    @post_attachment_caption = @post.comments.new(post_attachment_caption_params)
    @post_attachment_caption.user = Current.user

    respond_to do |format|
      if @post_attachment_caption.save
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
    if @post_attachment_caption.update(post_attachment_caption_params)
      flash[:notice] = "Comment was successfully updated."
      redirect_to @trip
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  def destroy
    @post_attachment_caption.destroy

    respond_to do |format|
      format.html { redirect_to post_url(@post), notice: "Comment was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Comment was successfully deleted." }
    end
  end

  private

  def set_post_attachment_caption
    @post_attachment_caption = PostComment.find(params.expect(:id))
  end

  def set_post
    @post = Post.find(@post_attachment_caption.post_id)
  end

  def set_trip
    @trip = @post.trip
  end

  # Only allow a list of trusted parameters through.
  def post_attachment_caption_params
    params.require(:post_attachment_caption).permit(:content, :post_id)
  end
end
