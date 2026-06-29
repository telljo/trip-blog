# Preview all emails at http://localhost:3000/rails/mailers/trip_mailer
class TripMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/trip_mailer/new_trip_subscription_email
  def new_trip_subscription_email
    TripMailer.new_trip_subscription_email(TripFollower.first)
  end
end
