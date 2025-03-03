require "base64"

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
    @post = Post.new(post_params.except(:attachments))
    @post.trip = @trip
    @post.user = Current.user

    attachments = params[:post][:attachments].select { |attachment| attachment.is_a?(ActionDispatch::Http::UploadedFile) }
    validate_attachments(attachments)

    respond_to do |format|
      if @post.errors.any?
        format.html { render :new, status: :unprocessable_entity, notice: @post.errors.first.full_message }
      elsif @post.save
        # Process attachments in the background
        attachment_data = attachments.map do |attachment|
          { content: Base64.encode64(attachment.read), filename: attachment.original_filename, content_type: attachment.content_type }
        end
        ProcessAttachmentsJob.perform_later(@post.id, attachment_data)

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
    ap post_params
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

  def validate_attachments(attachments)
    attachments.each do |attachment|
      unless attachment.content_type.in?(%w[image/png image/jpeg video/mp4 video/avi video/mov])
        @post.errors.add(:image, "Attachment type is not supported")
      end
    end
  end

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
    params.require(:post).permit(
      :title, :body,
      :trip_id,
      :latitude, :longitude,
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
