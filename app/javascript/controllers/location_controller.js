import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="location"
export default class extends Controller {
  static targets = ["address", "latitude", "longitude"];

  connect() {
    this.findLocation();
  }

  findLocation() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        this.handleSuccess.bind(this),
        this.handleError.bind(this)
      )
    } else {
      console.error("Geolocation is not supported by this browser.")
    }
  }

  handleSuccess(position) {
    const { latitude, longitude } = position.coords;
    this.longitudeTarget.value = longitude;
    this.latitudeTarget.value = latitude;
    console.log(this.longitudeTarget.value, this.latitudeTarget.value);
  }

  handleError(error) {
    console.error(`Geolocation error: ${error.message}`);
  }
}
