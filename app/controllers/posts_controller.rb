require "base64"

class PostsController < ApplicationController
  include PostNotifier
  skip_before_action :authenticate, only: %i[index show]
  before_action :set_post, only: %i[show edit update destroy remove_attachment]
  before_action :ensure_publicly_visible_or_authorized, only: %i[show]
  before_action :redirect_to_canonical_show_url, only: %i[show]
  before_action :set_trip, only: %i[edit update destroy remove_attachment]
  before_action :validate_user, only: %i[edit update destroy]

  # GET /posts
  def index
    if params[:trip_id]
      @trip = Trip.find(params[:trip_id])
      posts = can_manage_trip?(@trip) ? @trip.posts : @trip.visible_posts
      @pagy, @posts = pagy(:countless, posts.order(:id), limit: 5)
    else
      posts = Post.visible_to(Current.user)
      @pagy, @posts = pagy(:countless, posts.order(:id), limit: 5)
    end
  end

  # GET /posts/1
  def show
  end

  # GET /posts/new
  def new
    @trip = Trip.find(params[:trip_id])
    @post = @trip.posts.new
    authorize @post
  end

  # GET /posts/1/edit
  def edit
    authorize @post
  end

  # POST /posts
  def create
    @trip = Trip.find(params[:trip_id])
    @post = Post.new(post_params)
    @post.trip = @trip
    @post.user = Current.user

    respond_to do |format|
      if @post.errors.any?
        format.html { render :new, status: :unprocessable_entity, notice: @post.errors.first.full_message }
      elsif @post.save
        format.html do
          flash[:notice] = "Post was successfully created."
          redirect_to @trip
        end
        format.turbo_stream { flash.now[:notice] = "Post was successfully created." }
      else
        format.html { render @trip, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  def update
    authorize @post

    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @trip }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  def destroy
    authorize @post
    @post.destroy

    respond_to do |format|
      format.html { redirect_to trip_url(@trip), notice: "Post was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Post was successfully deleted." }
    end
  end

  def remove_attachment
    authorize @post, :update?
    attachment = @post.attachments_attachments.find(params.expect(:attachment_id))

    attachment.caption&.destroy!
    attachment.purge_later

    redirect_to edit_post_url(@post)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_post
    @post = Post.find(params.expect(:id))
    raise ActiveRecord::RecordNotFound if params[:trip_id].present? && @post.trip_id != params[:trip_id].to_i
  end

  def set_trip
    @trip = @post.trip
  end

  def ensure_publicly_visible_or_authorized
    return if @post.draft? == false && @post.hidden? == false
    return if can_manage_trip?(@post.trip)

    raise ActiveRecord::RecordNotFound
  end

  def redirect_to_canonical_show_url
    return if request.path == post_path(@post)

    redirect_to post_url(@post), status: :moved_permanently
  end

  def can_manage_trip?(trip)
    Current.user == trip.user || trip.users.include?(Current.user)
  end

  def validate_user
    return if @trip.user == Current.user || @trip.users.include?(Current.user)

    redirect_to @trip, notice: "You are not authorized to perform this action."
  end

  # Only allow a list of trusted parameters through.
  def post_params
    params.require(:post).permit(
      :title, :body,
      :trip_id,
      :latitude,
      :longitude,
      :draft,
      :hidden,
      :travel_type,
      attachments: [],
      post_attachment_captions_attributes: [
        :id,
        :attachment_id,
        :post_id,
        :text,
        :_destroy
      ]
    )
  end
end
