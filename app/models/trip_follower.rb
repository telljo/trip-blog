class TripFollower < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  validates :trip_id, uniqueness: { scope: :user_id }
end
