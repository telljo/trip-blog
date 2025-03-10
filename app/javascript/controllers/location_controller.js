import { Controller } from "@hotwired/stimulus"
import maplibregl from 'maplibre-gl';

// Connects to data-controller="location"
export default class extends Controller {
  static targets = ["map", "latitude", "longitude", "selectedLocation", "selectedAddress"];
  static values = { lng: Number, lat: Number };

  connect() {
    this.map = null;
    this.mapMarkers = [];
    this.selectedCoordinates = null;

    const longitude = this.lngValue;
    const latitude = this.latValue;

    if (longitude && latitude) {
      this.initializeMap(longitude, latitude);
    } else {
      this.findLocation();
    }
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

    this.initializeMap(longitude, latitude);
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch("/geolocations/find_location", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ latitude, longitude }),
    })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`)
      }
      return response.json()
    })
    .then((data) => {
      this.selectedAddressTarget.value = data.formatted_address;
      this.selectedCoordinates = [longitude, latitude];
    })
    .catch((error) => {
      console.error("Error communicating with Rails:", error)
    })
  }

  initializeMap(longitude, latitude) {
    // Clear the map container
    this.mapTarget.innerHTML = '';

    this.map = new maplibregl.Map({
      container: this.mapTarget,
      attributionControl: {
        compact: true
      },
      style: 'https://api.maptiler.com/maps/hybrid/style.json?key=YceGCelRYIEShW1l58mK',
      center: [longitude, latitude],
      zoom: 6
    });

    this.map.on('load', () => {
      this.map.resize();

      // Add marker after map is fully loaded and resized
      const marker = new maplibregl.Marker()
        .setLngLat([longitude, latitude])
        .addTo(this.map);

      this.mapMarkers.push(marker);
    });
  }

  handleError(error) {
    console.error(`Geolocation error: ${error.message}`);
  }

  chooseLocation(event) {
    event.preventDefault();
    event.stopPropagation();
    this.selectedAddressTarget.value = event.target.textContent;
    this.updateMap(event.target.value.split(',').map(parseFloat));
  }

  updateMap(coordinates) {
    if (this.mapMarkers.length > 0) {
      this.mapMarkers.forEach(marker => marker.remove());
      this.mapMarkers = [];
    }

    this.addMarker(coordinates);

    this.map.flyTo({
      center: coordinates,
      essential: true
    });
  }

  addMarker(coordinates) {
    const marker = new maplibregl.Marker()
      .setLngLat(coordinates)
      .addTo(this.map);

    this.mapMarkers.push(marker);
    this.selectedCoordinates = coordinates;
  }

  selectLocation() {
    if (this.selectedCoordinates === null) {
      console.error("No location selected");
      return;
    }
    const customEvent = new CustomEvent('location:selected', {
      detail: {
        longitude: this.selectedCoordinates[0],
        latitude: this.selectedCoordinates[1],
        address: this.selectedAddressTarget.value
      }
    });

    window.dispatchEvent(customEvent);
  }
}
