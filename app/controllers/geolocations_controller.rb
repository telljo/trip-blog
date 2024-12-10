class GeolocationsController < ApplicationController
  def search
    if params[:longitude].present? && params[:latitude].present? && params[:address].present?
      @current_address = params[:address]
      @current_latitude =  params[:latitude]
      @current_longitude = params[:longitude]
    end

    return unless params[:query].present?

    @geolocations = Geocoder.search(params[:query]).map do |loc|
      [
        loc.address,
        "#{loc.geometry['location']['lng']},#{loc.geometry['location']['lat']}"
      ]
    end
  end

  def find_location
    # Access latitude and longitude parameters sent from frontend
    latitude = params[:latitude]
    longitude = params[:longitude]

    location_data = Geocoder.search([ latitude, longitude ])

    render json: location_data.first.data
  end
end
