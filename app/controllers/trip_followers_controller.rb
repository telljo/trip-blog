class TripFollowersController < ApplicationController
  before_action :set_trip_follower, only: %i[destroy]
  before_action :set_trip, only: %i[create destroy]

  def create
    @trip_follower = @trip.followers.new(user: Current.user)

    respond_to do |format|
      if @trip_follower.save
        format.html do
          redirect_to @trip_follower.trip
        end
      else
        format.html { render @trip_follower.trip, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @trip_follower.destroy

    respond_to do |format|
      format.html do
        redirect_to @trip_follower.trip
      end
    end
  end

  private

  def set_trip_follower
    @trip_follower = TripFollower.find(params.expect(:id))
  end

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end
end
