import { add, Controller } from "@hotwired/stimulus"
import maplibregl from 'maplibre-gl';

// Connects to data-controller="location"
export default class extends Controller {
  static targets = ["map", "latitude", "longitude", "address", "selectedLocation", "selectedAddress", "searchQuery", "searchResults"];
  static values = {
    lng: Number,
    lat: Number,
    address: String
  };
  static debounceTimeout = null;

  connect() {
    this.map = null;
    this.mapMarkers = [];
    this.selectedCoordinates = null;

    const longitude = this.lngValue;
    const latitude = this.latValue;
    const address = this.addressValue;

    if (longitude && latitude) {
      this.initializeMap(longitude, latitude);
      this.selectedAddressTarget.value = address || '';
    } else {
      this.findLocation();
    }
  }

  get csrfToken() {
    if (!this._csrfToken) {
      this._csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    }
    return this._csrfToken;
  }

  disconnect() {
    // Clean up map resources
    if (this.map) {
      this.map.remove();
      this.map = null;
    }

    // Clear any pending timeouts
    clearTimeout(this.constructor.debounceTimeout);
  }

  search(event) {
    event.preventDefault();
    if (this.searchQueryTarget.value.length < 3) {
      this.clearSearchResults();
      return;
    }

    // Clear previous timeout
    clearTimeout(this.constructor.debounceTimeout);

    // Set new timeout
    this.constructor.debounceTimeout = setTimeout(() => {
      this.executeSearch();
    }, 400);
  }

  executeSearch() {
    const query = encodeURIComponent(this.searchQueryTarget.value.trim());

    if (!query) {
      this.clearSearchResults();
      return;
    }

    fetch(`/geolocations/search?query=${query}`, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
    })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`)
      }
      return response.json()
    })
    .then((data) => {
      this.updateSearchResults(data);
    })
    .catch((error) => {
      console.error("Error communicating with Rails:", error)
    })
  }

  updateSearchResults(data) {
    if(data.length == 0) {
      this.searchResultsTarget.classList.add("visually-hidden");
      return;
    }
    this.clearSearchResults();
    this.searchResultsTarget.classList.remove("visually-hidden");

    data.forEach(item => {
      const option = document.createElement("option");
      option.value = item[1];
      option.textContent = item[0];
      this.searchResultsTarget.appendChild(option);
    });
  }

  clearSearchResults() {
    this.searchResultsTarget.innerHTML = "";
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

      // Register the MapLibre GL click event
      this.map.on('click', (event) => {
        this.clickMap(event); // Pass the MapLibre GL event to clickMap
      });
    });
  }

  handleError(error) {
    console.error(`Geolocation error: ${error.message}`);
  }

  clickMap(event) {
    event.preventDefault();
    if (!event.lngLat) {
      console.error("Invalid event: Missing lngLat property");
      return;
    }
    const coordinates = [event.lngLat.lng, event.lngLat.lat];
    this.chooseLocation(event, coordinates, null);
  }

  chooseLocation(event, coordinates = null, address = null) {
    event.preventDefault();
    const coords = coordinates || event.target.value.split(',').map(parseFloat);

    this.longitudeTarget.value = coords[0];
    this.latitudeTarget.value = coords[1];
    this.addressTarget.value = address ? address : this.addressTarget.value = coords.join(", ");
    this.searchResultsTarget.classList.add("visually-hidden");
    this.selectedAddressTarget.value = address ? address : this.addressTarget.value = coords.join(", ");
    this.updateMap(coords);
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

  cancelUpdate(event) {
    if (this.lngValue && this.latValue) {
      const coordinates = [this.lngValue, this.latValue];
      this.chooseLocation(event, coordinates, this.addressValue);
    }
  }
}
