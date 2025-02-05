class PostsController < ApplicationController
  include PostNotifier
  before_action :set_post, only: %i[show edit update destroy]
  before_action :set_trip, only: %i[show edit update destroy]
  before_action :validate_user, only: %i[edit update destroy]

  # GET /posts
  def index
    if params[:trip_id]
      @trip = Trip.find(params[:trip_id])
      @pagy, @posts = pagy_countless(@trip.posts.order(:id), items: 5)
    else
      @pagy, @posts = pagy_countless(Post.all.order(:id), items: 5)
    end
  end

  # GET /posts/1
  def show
  end

  # GET /posts/new
  def new
    @trip = Trip.find(params[:trip_id])
    @post = @trip.posts.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  def create
    @trip = Trip.find(params[:trip_id])
    @post = Post.new(post_params)
    @post.trip = @trip
    @post.user = Current.user

    respond_to do |format|
      if @post.save
        format.html do
          flash[:notice] = "Post was successfully created."
          redirect_to @trip
        end
        format.turbo_stream
      else
        format.html { render @trip, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  def update
    if @post.update(post_params)
      flash[:notice] = "Post was successfully updated."
      redirect_to @trip
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to trip_url(@trip), notice: "Post was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Post was successfully deleted." }
    end
  end

  def remove_attachment
    @attachment = ActiveStorage::Attachment.find(params[:id])

    @attachment.variant_records.destroy_all
    @attachment.purge_later

    redirect_to edit_post_url(@attachment.record)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_post
    @post = Post.find(params.expect(:id))
  end

  def set_trip
    @trip = @post.trip
  end

  def validate_user
    return if @trip.user == Current.user || @trip.users.include?(Current.user)

    redirect_to @trip, notice: "You are not authorized to perform this action."
  end

  # Only allow a list of trusted parameters through.
  def post_params
    params.require(:post).permit(:title, :body, :trip_id, :latitude, :longitude, attachments: [])
  end
end
