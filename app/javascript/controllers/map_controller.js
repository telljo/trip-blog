import { Controller } from "@hotwired/stimulus"
import maplibregl from 'maplibre-gl';

export default class extends Controller {
  static targets = ["map"];

  static coordinatesMap = {};
  static map = null;

  connect() {
    const mapElement = this.mapTarget;
    mapElement.innerHTML = '';
    const points = JSON.parse(mapElement.dataset.points);

    // Initialize coordinatesMap
    this.constructor.coordinatesMap = points.reduce((acc, point) => {
      acc[point.postId] = [point.longitude, point.latitude];
      return acc;
    }, {});

    const firstPoint = points[0];

    this.constructor.map = new maplibregl.Map({
      container: mapElement,
      style: 'https://api.maptiler.com/maps/hybrid/style.json?key=YceGCelRYIEShW1l58mK',
      center: [firstPoint.longitude, firstPoint.latitude],
      zoom: 5
    });

    points.forEach(point => {
      new maplibregl.Marker()
        .setLngLat([point.longitude, point.latitude])
        .setPopup(new maplibregl.Popup({
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

    const coordinates = this.constructor.coordinatesMap[postId];

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