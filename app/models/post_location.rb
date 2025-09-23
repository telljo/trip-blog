class PostLocation < ApplicationRecord
  belongs_to :post

  reverse_geocoded_by :latitude, :longitude do |obj, results|
    if geo = results.first
      obj.street  = geo.street_address
      obj.city    = geo.city
      obj.state   = geo.state
      obj.country = geo.country
    else
      Rails.logger.debug "Geocoding results are empty for latitude: #{obj.latitude}, longitude: #{obj.longitude}"
    end
  end
  after_validation :reverse_geocode

  def address
    [ street, city, state, country ].compact.join(", ")
  end

  def short_address
    [ city, state, country ].compact.join(", ")
  end
end
