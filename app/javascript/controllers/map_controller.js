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

    const coordinates = points.map(point => [point.longitude, point.latitude]);

    this.map.on('load', () => {
      this.map.addSource('route', {
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

      this.map.addLayer({
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