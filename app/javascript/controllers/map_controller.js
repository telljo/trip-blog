import { Controller } from "@hotwired/stimulus"
import maplibregl from 'maplibre-gl';

export default class extends Controller {
  static targets = ["map"];

  connect() {
    if(!this.hasMapTarget) {
      return;
    }
    this.coordinatesMap = {};
    this.map = null;
    this.currentPostId = null;

    const mapElement = this.mapTarget;
    mapElement.innerHTML = '';
    const points = JSON.parse(mapElement.dataset.points);

    // Initialize coordinatesMap
    this.coordinatesMap = points.reduce((acc, point) => {
      acc[point.postId] = [point.longitude, point.latitude];
      return acc;
    }, {});

    const firstPoint = points[0];

    this.map = new maplibregl.Map({
      container: mapElement,
      style: 'https://api.maptiler.com/maps/hybrid/style.json?key=YceGCelRYIEShW1l58mK',
      center: [firstPoint.longitude, firstPoint.latitude],
      zoom: 10
    });

    points.forEach(point => {
      new maplibregl.Marker()
        .setLngLat([point.longitude, point.latitude])
        .setPopup(new maplibregl.Popup({
          closeButton: false,
          closeOnClick: true,
          closeOnMove: true
         }).setHTML(point.tooltip))
        .addTo(this.map);
    });

    const pointData = points.reverse().map((point, index) => {
      if (index == points.length - 1) {
        return;
      }
      let nextPoint = points[index + 1];
      return {
        coordinates: [
          [point.longitude, point.latitude], // Current point
          [nextPoint.longitude, nextPoint.latitude] // Next point
        ],
        travelType: nextPoint.travelType // Use travelType of the second point
      };
    }).filter(Boolean);

    this.map.on('load', () => {

      this.map.addSource('route', {
        'type': 'geojson',
        'data': {
          'type': 'FeatureCollection',
          'features': pointData.map(pd => ({
            'type': 'Feature',
            'properties': {
              'travelType': pd.travelType
            },
            'geometry': {
              'type': 'LineString',
              'coordinates': pd.coordinates
            }
          }))
        }
      });

      this.map.addLayer({
        'id': 'route',
        'type': 'line',
        'source': 'route',
        'layout': {},
        'paint': {
          'line-color': [
            'match',
            ['get', 'travelType'],
            'air', '#FF0000', // Red for air
            'ocean', '#00FF00', // Green for bike
            '#FFF' // White for others
          ],
          'line-width': 4
        }
      });
    });

    // Bind to the scroll event
    window.addEventListener('scroll', this.handleScroll.bind(this));
  }

  handleScroll() {
    const scrollPosition = window.scrollY + window.innerHeight / 2;
    let currentPost = null;
    this.posts = document.querySelectorAll('.post');

    if(this.posts.length > 0 && this.currentPostId === null) {
      this.currentPostId = this.posts[0].firstElementChild.id.split('_')[1];
    }

    for (const post of this.posts) {
      const postTop = post.offsetTop;
      const postBottom = postTop + post.offsetHeight;

      if (scrollPosition >= postTop && scrollPosition <= postBottom) {
        const postId = post.firstElementChild.id.split('_')[1];
        if (this.currentPostId !== postId) {
          this.currentPostId = postId;
          currentPost = post;
          break;
        }
      }
    }

    if (currentPost && this.coordinatesMap[this.currentPostId]) {
      const [longitude, latitude] = this.coordinatesMap[this.currentPostId];
      this.map.flyTo({
        center: [longitude, latitude],
        zoom: 10,
        essential: true
      });
    }
  }

  moveToMarker(event) {
    const postId = event.target.dataset.postId;

    const coordinates = this.coordinatesMap[postId];

    if (coordinates) {
      this.map.flyTo({
        center: coordinates,
        zoom: 10,
        essential: true
      });
    } else {
      console.error(`Coordinates not found for postId: ${postId}`);
    }
  }
}