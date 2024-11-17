class TripsController < ApplicationController
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
  end

  # GET /trips/1/edit
  def edit
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
    respond_to do |format|
      if @trip.update(trip_params)
        format.html { redirect_to trips_url }
        format.turbo_stream { flash.now[:notice] = "Trip was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trips/1
  def destroy
    @trip.destroy!
    redirect_to trips_path, notice: "Trip was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trip
      @trip = Trip.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def trip_params
      params.require(:trip).permit(:name, :body)
    end
end
