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
    this.boatImagePath = mapElement.dataset.boatImagePath;
    this.planeImagePath = mapElement.dataset.planeImagePath;
    this.busImagePaths = [mapElement.dataset.busLeftImagePath,mapElement.dataset.busRightImagePath];
    this.trainImagePath = mapElement.dataset.trainImagePath;

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

    this.initaliseMapImages();

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

    this.addMapLayers(points);

    // Bind to the scroll event
    window.addEventListener('scroll', this.handleScroll.bind(this));
  }

  async initaliseMapImages() {
    const planeImage = await this.map.loadImage(this.planeImagePath);
    this.map.addImage('plane', planeImage.data);

    const boatImage = await this.map.loadImage(this.boatImagePath);
    this.map.addImage('boat', boatImage.data);

    const busImageLeft = await this.map.loadImage(this.busImagePaths[0]);
    this.map.addImage('bus-left', busImageLeft.data);
    const busImageRight = await this.map.loadImage(this.busImagePaths[1]);
    this.map.addImage('bus-right', busImageRight.data);

    const trainImage = await this.map.loadImage(this.trainImagePath);
    this.map.addImage('train', trainImage.data);
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
        const postId = post.id.split('_')[1];
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

  addMapLayers(points) {
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
        bearing: this.getBearing([point.longitude, point.latitude], [nextPoint.longitude, nextPoint.latitude]),
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
              'travelType': pd.travelType,
              'bearing': pd.bearing
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
          'line-color': '#FFF',
          'line-width': 2,
          'line-dasharray': [2, 1]
        }
      });

       // Symbol for bus travel
       this.map.addLayer({
        'id': 'symbol-bus',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'bus-left',                  // Use flipped icon
                'bus-right'                  // Otherwise, use normal icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
        },
        'filter': ['==', ['get', 'travelType'], 'bus']
      });

      // Symbol for plane travel
      this.map.addLayer({
        'id': 'symbol-plane',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': 'plane',
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2
            },
        'filter': ['==', ['get', 'travelType'], 'plane']
      });

      // Symbol for boat travel
      this.map.addLayer({
        'id': 'symbol-boat',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': 'boat',
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2
        },
        'filter': ['==', ['get', 'travelType'], 'boat']
      });
    });
  }

  getBearing(firstCoordinates, secondCoordinates) {
    const lat1 = firstCoordinates[1];
    const lon1 = firstCoordinates[0];
    const lat2 = secondCoordinates[1];
    const lon2 = secondCoordinates[0];

    const y = Math.sin(lon2 - lon1) * Math.cos(lat2);
    const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(lon2 - lon1);
    let brng = Math.atan2(y, x);
    brng = brng * (180 / Math.PI);
    brng = (brng + 360) % 360;

    return brng;
  }
}