class TripFollowerPropagator
  def initialize(trip)
    @trip = trip
  end

  def call
    follower_user_ids.each do |user_id|
      trip_follower = @trip.followers.find_or_create_by!(user_id: user_id)
      next unless trip_follower.previously_new_record?

      TripMailer.new_trip_subscription_email(trip_follower).deliver_later
    end
  end

  private

  def follower_user_ids
    TripFollower
      .where(trip_id: source_trip_ids)
      .where.not(user_id: @trip.user_id)
      .distinct
      .pluck(:user_id)
  end

  def source_trip_ids
    Trip
      .where(user_id: @trip.user_id)
      .or(Trip.where(id: TripCompanion.where(user_id: @trip.user_id).select(:trip_id)))
      .where.not(id: @trip.id)
      .select(:id)
  end
end
