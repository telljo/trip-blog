import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl";

export default class extends Controller {
  static targets = ["map"];

  static coordinatesMap = {};
  static map = null;

  connect() {
    mapboxgl.accessToken = 'pk.eyJ1IjoidGVsbGpvIiwiYSI6ImNtMnU0d2N5NzBhbXAyaXB4Ym1tM3A2cnMifQ.CxCQDXvDYdTte4eXrsvRhA';

    const mapElement = this.mapTarget;
    mapElement.innerHTML = '';
    const points = JSON.parse(mapElement.dataset.points);

    // Initialize coordinatesMap
    this.constructor.coordinatesMap = points.reduce((acc, point) => {
      acc[point.postId] = [point.longitude, point.latitude];
      return acc;
    }, {});

    const firstPoint = points[0];

    this.constructor.map = new mapboxgl.Map({
      container: mapElement,
      style: 'mapbox://styles/mapbox/satellite-v9',
      center: [firstPoint.longitude, firstPoint.latitude],
      zoom: 5
    });

    points.forEach(point => {
      new mapboxgl.Marker()
        .setLngLat([point.longitude, point.latitude])
        .setPopup(new mapboxgl.Popup({
          closeButton: false,
          closeOnClick: true,
          closeOnMove: true
         }).setHTML(point.tooltip))
        .addTo(this.constructor.map);
    });

    const coordinates = points.map(point => [point.longitude, point.latitude]);

    this.constructor.map.on('load', () => {
      this.constructor.map.addSource('route', {
        'type': 'geojson',
        'data': {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': coordinates
          }
        }
      });

      this.constructor.map.addLayer({
        'id': 'route',
        'type': 'line',
        'source': 'route',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round'
        },
        'paint': {
          'line-color': '#fff',
        }
      });
    });
  }

  moveToMarker(event) {
    const postId = event.target.dataset.postId;

    // Assuming you have a function to get coordinates by postId
    const coordinates = this.constructor.coordinatesMap[postId];

    // Assuming 'map' is your Mapbox GL map instance
    if (coordinates) {
      this.constructor.map.flyTo({
        center: coordinates,
        essential: true // this animation is considered essential with respect to prefers-reduced-motion
      });
    } else {
      console.error(`Coordinates not found for postId: ${postId}`);
    }
  }
}