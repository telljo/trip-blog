class TripCompanionsController < ApplicationController
  before_action :set_trip

  # GET /trip_companions
  def index
    @trip_companions = @tip.companions
  end

  # GET /trips/new
  def new
    @trip_companion = TripCompanion.new(trip_id: @trip.id)
  end

  # POST /trips/:trip_id/trip_companions
  def create
    @companion = @trip.companions.new(trip_companion_params)

    respond_to do |format|
      if @companion.save
        format.html do
          flash[:notice] = "Companion was successfully added to your trip."
          redirect_to @trip
        end
        format.turbo_stream { flash.now[:notice] = "Companion was was successfully added to your trip." }
      else
        format.html { render trips_url, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trips/:trip_id/trip_companions/:id
  def destroy
    @companion = @trip.companions.find(params[:id])
    @companion.destroy
    flash[:notice] = "Companion was successfully removed."
    redirect_to @trip
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def trip_companion_params
    params.require(:trip_companion).permit(:user_id)
  end
end
