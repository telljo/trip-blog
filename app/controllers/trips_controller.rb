class TripsController < ApplicationController
  skip_before_action :authenticate, only: %i[ index show ]
  before_action :set_trip, only: %i[ show edit update destroy ]

  # GET /trips
  def index
    @trips = Trip.all
  end

  # GET /trips/1
  def show
  end

  # GET /trips/new
  def new
    @trip = Trip.new
    @trip.companions.build
  end

  # GET /trips/1/edit
  def edit
    @trip.companions.build if @trip.companions.empty?
  end

  # POST /trips
  def create
    @trip = Trip.new(trip_params.merge(user: Current.user))

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
    if @trip.update(trip_params)
      redirect_to @trip
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
end
