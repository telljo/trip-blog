class TripsController < ApplicationController
  skip_before_action :authenticate, only: %i[ index show ]
  before_action :set_trip, only: %i[ show edit update destroy ]

  # GET /trips
  def index
    @trips = Trip.all
  end

  # GET /trips/1
  def show
    posts = (Current.user == @trip.user || @trip.users.include?(Current.user)) ? @trip.posts : @trip.visible_posts
    if filter_params[:country].present?
      posts = posts.where(country: filter_params[:country])
      if filter_params[:query].present?
        @pagy, @posts = pagy(posts.full_text_search(input: filter_params[:query], trip: @trip, posts: posts).order(created_at: :desc), items: 5)
      else
        @pagy, @posts = pagy(posts.order(created_at: :desc), items: 5)
      end
    elsif filter_params[:query].present?
      @pagy, @posts = pagy(Post.full_text_search(input: filter_params[:query], trip: @trip, posts: posts).order(created_at: :desc), items: 5)
    else
      @pagy, @posts = pagy(posts.order(created_at: :desc), items: 5)
    end
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /trips/new
  def new
    @trip = Trip.new
    @trip.companions.build
    @trip.user = Current.user
    authorize @trip
  end

  # GET /trips/1/edit
  def edit
    authorize @trip
    @trip.companions.build if @trip.companions.empty?
  end

  # POST /trips
  def create
    @trip = Trip.new(trip_params)

    respond_to do |format|
      if @trip.save
        format.html do
          flash[:notice] = "Trip was successfully created."
          redirect_to trips_url
        end
        format.turbo_stream { flash.now[:notice] = "Trip was successfully created." }
      else
        format.html { render trips_url, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trips/1
  def update
    authorize @trip
    if @trip.update(trip_params)
      flash[:notice] = "Trip was successfully updated."
      redirect_to trips_url(@trip)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /trips/1
  def destroy
    @trip.destroy!
    redirect_to trips_path, notice: "Trip was successfully destroyed.", status: :see_other
  end

  private

  def set_trip
    @trip = Trip.find(params.expect(:id))
  end

  def trip_params
    params.require(:trip).permit(:name, :body, companions_attributes: [ :id, :user_id, :_destroy ]).tap do |whitelisted|
      whitelisted[:companions_attributes]&.reject! { |_, companion| companion[:user_id].blank? }
    end
  end

  def filter_params
    params.fetch(:filters, {}).permit(:country, :query)
  end
end
