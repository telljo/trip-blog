import { Controller } from "@hotwired/stimulus"
import { Map, FullscreenControl } from 'maplibre-gl';

export default class extends Controller {
  static targets = ["map"];

  connect() {
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));

    if(!this.hasMapTarget) {
      return;
    }
    this.coordinatesMap = {};
    this.map = null;
    this.currentPostId = null;
    const mapElement = this.mapTarget;
    mapElement.innerHTML = '';

    const points = JSON.parse(mapElement.dataset.points);

    this.coordinatesMap = points.reduce((acc, point) => {
      acc[point.postId] = point.locations
        .map((location) => ({
          postLocationId: location.postLocationId,
          longitude: location.longitude,
          latitude: location.latitude
        }))
        .sort((a, b) => a.postLocationId - b.postLocationId);
      return acc;
    }, {});

    console.log(this.coordinatesMap);

    const firstPoint = points[0];
    const firstPointLastLocation = firstPoint.locations[firstPoint.locations.length - 1];

    this.map = new maplibregl.Map({
      container: mapElement,
      style: 'https://api.maptiler.com/maps/hybrid/style.json?key=YceGCelRYIEShW1l58mK',
      center: [firstPointLastLocation.longitude, firstPointLastLocation.latitude],
      zoom: 10
    });

    this.map.addControl(new FullscreenControl({container: document.querySelector('body')}));
    this.initaliseMapImages();

    points.forEach(point => {
      point.locations.forEach(location => {
        new maplibregl.Marker()
        .setLngLat([location.longitude, location.latitude])
        .setPopup(new maplibregl.Popup({
          closeButton: false,
          closeOnClick: true,
          closeOnMove: true
         }).setHTML(point.tooltip))
        .addTo(this.map);
      });
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

    // Load walking images
    const walkingImageLeft = await this.map.loadImage(images.walking.left);
    this.map.addImage('walking-left', walkingImageLeft.data);
    const walkingImageRight = await this.map.loadImage(images.walking.right);
    this.map.addImage('walking-right', walkingImageRight.data);

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

    // Load nina images
    const ninaImageLeft = await this.map.loadImage(images.nina.left);
    this.map.addImage('nina-left', ninaImageLeft.data);
    const ninaImageRight = await this.map.loadImage(images.nina.right);
    this.map.addImage('nina-right', ninaImageRight.data);

    // Load rickshaw images
    const rickshawImageLeft = await this.map.loadImage(images.rickshaw.left);
    this.map.addImage('rickshaw-left', rickshawImageLeft.data);
    const rickshawImageRight = await this.map.loadImage(images.rickshaw.right);
    this.map.addImage('rickshaw-right', rickshawImageRight.data);

    // Load train images
    const trainImageLeft = await this.map.loadImage(images.train.left);
    this.map.addImage('train-left', trainImageLeft.data);
    const trainImageRight = await this.map.loadImage(images.train.right);
    this.map.addImage('train-right', trainImageRight.data);
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
      const postLocations = this.coordinatesMap[this.currentPostId];
      const [longitude, latitude] = postLocations[postLocations.length - 1].coordinates;
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
    // const pointData = cachedPointData ? JSON.parse(cachedPointData) : this.processPointData(points, cacheKey);
    console.log('Points:', points);
    const pointData = this.processPointData(points, cacheKey);
    console.log('Point Data:', pointData);

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
            'symbol-spacing': 100,
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
            'symbol-spacing': 100,
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
            'symbol-spacing': 100,
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

      // Symbol for walking travel
      this.map.addLayer({
        'id': 'symbol-walking',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'walking-right',                    // Otherwise, use normal icon
                'walking-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 100,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'walking']
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
            'symbol-spacing': 100,
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

      // Symbol for nina travel
      this.map.addLayer({
        'id': 'symbol-nina',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'nina-right',                    // Otherwise, use normal icon
                'nina-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 100,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'nina']
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
            'symbol-spacing': 100,
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
            'symbol-spacing': 100,
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

      // Symbol for train travel
      this.map.addLayer({
        'id': 'symbol-train',
        'type': 'symbol',
        'source': 'route',
        'layout': {
            'icon-image': [
                'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                'train-right',                    // Otherwise, use normal icon
                'train-left'                      // Use flipped icon
            ],
            'symbol-placement': 'line',
            'symbol-spacing': 100,
            'icon-size': 0.2,
            'icon-rotate': [
              'case',
                ['<', ['get', 'bearing'], 180], // If bearing < 180
                360,
                180
            ]
        },
        'filter': ['==', ['get', 'travelType'], 'train']
      });
    });
  }

  processPointData(points, cacheKey) {
    if (!points || points.length < 2) return [];

    // Reverse if you need chronological order
    const orderedPoints = [...points].reverse();
    const data = orderedPoints.map((point, index) => {

      // Skip last point since it has no "next point"
    if (index === orderedPoints.length - 1) return null;

      const nextPoint = orderedPoints[index + 1];
      const currentLocations = point.locations;
      const nextLocations = nextPoint.locations;

      // Use the last location of current post and first location of next post
      const lastLoc = currentLocations[currentLocations.length - 1];
      const firstNextLoc = nextLocations[0];

      console.log(lastLoc);

      if (!lastLoc || !firstNextLoc) return null;

      return {
        coordinates: [
          [lastLoc.longitude, lastLoc.latitude], // Current point
          [firstNextLoc.longitude, firstNextLoc.latitude] // Next point
        ],
        bearing: this.getBearing(
          [lastLoc.longitude, lastLoc.latitude],
          [firstNextLoc.longitude, firstNextLoc.latitude]
        ),
        travelType: firstNextLoc.travelType // Travel type is associated with the next point
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