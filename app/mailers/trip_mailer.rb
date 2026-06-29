class TripMailer < ApplicationMailer
  def new_trip_subscription_email(trip_follower)
    @trip_follower = trip_follower
    @trip = trip_follower.trip
    @creator = @trip.user
    @follower = trip_follower.user

    mail(
      to: @follower.email,
      subject: "A new Footprints trip from #{@creator.username} - #{@trip.name}"
    )
  end
end
