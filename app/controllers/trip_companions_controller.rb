class TripCompanionsController < ApplicationController
  before_action :set_trip

  # GET /trip_companions
  def index
    @trip_companions = @trip.companions
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end
end
