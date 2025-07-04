import { Controller } from "@hotwired/stimulus"
import { Map, FullscreenControl } from 'maplibre-gl';

export default class extends Controller {
  static targets = ["map"];

  connect() {
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
    const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));

    if(!this.hasMapTarget) {
      return;
    }
    this.coordinatesMap = {};
    this.map = null;
    this.currentPostId = null;
    const mapElement = this.mapTarget;
    mapElement.innerHTML = '';

    // Potentially add caching with this??????
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

    this.map.addControl(new FullscreenControl({container: document.querySelector('body')}));


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
    const images = JSON.parse(this.mapTarget.dataset.images);
    // Load boat images
    const boatImageLeft = await this.map.loadImage(images.boat.left);
    this.map.addImage('boat-left', boatImageLeft.data);
    const boatImageRight = await this.map.loadImage(images.boat.right);
    this.map.addImage('boat-right', boatImageRight.data);

    // Load bus images
    const busImageLeft = await this.map.loadImage(images.bus.left);
    this.map.addImage('bus-left', busImageLeft.data);
    const busImageRight = await this.map.loadImage(images.bus.right);
    this.map.addImage('bus-right', busImageRight.data);

    // Load plane images
    const planeImageLeft = await this.map.loadImage(images.plane.left);
    this.map.addImage('plane-left', planeImageLeft.data);
    const planeImageRight = await this.map.loadImage(images.plane.right);
    this.map.addImage('plane-right', planeImageRight.data);

    // Load walk images
    const walkImageLeft = await this.map.loadImage(images.walk.left);
    this.map.addImage('walk-left', walkImageLeft.data);
    const walkImageRight = await this.map.loadImage(images.walk.right);
    this.map.addImage('walk-right', walkImageRight.data);

    // Load motorbike images
    const motorbikeImageLeft = await this.map.loadImage(images.motorbike.left);
    this.map.addImage('motorbike-left', motorbikeImageLeft.data);
    const motorbikeImageRight = await this.map.loadImage(images.motorbike.right);
    this.map.addImage('motorbike-right', motorbikeImageRight.data);

    // Load car images
    const carImageLeft = await this.map.loadImage(images.car.left);
    this.map.addImage('car-left', carImageLeft.data);
    const carImageRight = await this.map.loadImage(images.car.right);
    this.map.addImage('car-right', carImageRight.data);

    // Load rickshaw images
    const rickshawImageLeft = await this.map.loadImage(images.rickshaw.left);
    this.map.addImage('rickshaw-left', rickshawImageLeft.data);
    const rickshawImageRight = await this.map.loadImage(images.rickshaw.right);
    this.map.addImage('rickshaw-right', rickshawImageRight.data);
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
    // If cached point data exists, use it. Otherwise, process the points and cache the result
    const cacheKey = `mapLayers_${JSON.stringify(points)}`;
    const cachedPointData = localStorage.getItem(cacheKey);
    const pointData = cachedPointData ? JSON.parse(cachedPointData) : this.processPointData(points, cacheKey);

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
                'bus-right',                    // Otherwise, use normal icon
                'bus-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
          },
          'filter': ['==', ['get', 'travelType'], 'bus']
        });

      // Symbol for plane travel
      this.map.addLayer({
        'id': 'symbol-plane',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'plane-right',                    // Otherwise, use normal icon
                'plane-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
          },
        'filter': ['==', ['get', 'travelType'], 'plane']
      });

      // Symbol for boat travel
      this.map.addLayer({
        'id': 'symbol-boat',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'boat-right',                    // Otherwise, use normal icon
                'boat-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'boat']
      });

      // Symbol for walk travel
      this.map.addLayer({
        'id': 'symbol-walk',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'walk-right',                    // Otherwise, use normal icon
                'walk-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'walk']
      });

      // Symbol for car travel
      this.map.addLayer({
        'id': 'symbol-car',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'car-right',                    // Otherwise, use normal icon
                'car-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'car']
      });

      // Symbol for motorbike travel
      this.map.addLayer({
        'id': 'symbol-motorbike',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'motorbike-right',                    // Otherwise, use normal icon
                'motorbike-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'motorbike']
      });

      // Symbol for rickshaw travel
      this.map.addLayer({
        'id': 'symbol-rickshaw',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'rickshaw-right',                    // Otherwise, use normal icon
                'rickshaw-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 200,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'rickshaw']
      });
    });
  }

  processPointData(points, cacheKey) {
    const data = points.reverse().map((point, index) => {
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

    localStorage.setItem(cacheKey, JSON.stringify(data));
    return data;
  }

  getBearing(firstCoordinates, secondCoordinates) {
    const toRadians = (degrees) => degrees * (Math.PI / 180);
    const lat1 = toRadians(firstCoordinates[1]);
    const lon1 = toRadians(firstCoordinates[0]);
    const lat2 = toRadians(secondCoordinates[1]);
    const lon2 = toRadians(secondCoordinates[0]);

    const y = Math.sin(lon2 - lon1) * Math.cos(lat2);
    const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(lon2 - lon1);
    let brng = Math.atan2(y, x);
    brng = brng * (180 / Math.PI);
    brng = (brng + 360) % 360;

    return brng;
  }
}