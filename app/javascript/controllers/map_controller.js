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
    this.prevCurrentPost = null;
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
    this.posts = document.querySelectorAll('.post');
    if (this.posts.length === 0) return;

    let currentPost = null;

    if(this.posts.length > 0 && !this.currentPostId) {
      this.currentPostId = this.posts[0].id.split('_')[1];
      this.prevCurrentPost = this.posts[0];
    }

    // Find the post currently centered on screen
    for (const post of this.posts) {
      const postTop = post.offsetTop;
      const postBottom = postTop + post.offsetHeight;

      if (scrollPosition >= postTop && scrollPosition <= postBottom) {
        const postId = post.id.split('_')[1];
        currentPost = post;

        if (currentPost !== this.prevCurrentPost) {
          this.currentPostId = postId;
          this.prevCurrentPost = currentPost;
          break;
        }
        currentPost = null;
      }
    }

    // If we have a current post with coordinates
    if (currentPost && this.currentPostId) {
      const postLocations = this.coordinatesMap[this.currentPostId].reverse();
      if (!postLocations || postLocations.length === 0) return;

      const postTop = currentPost.offsetTop;
      const postBottom = postTop + currentPost.offsetHeight;
      const postScrollY = scrollPosition - postTop;
      const postHeight = postBottom - postTop;

      // Determine progress (0 to 1) through the post
      const progress = Math.min(Math.max(postScrollY / postHeight, 0), 1);

      // Convert progress to index of post location
      const index = Math.floor(progress * (postLocations.length - 1));
      const loc = postLocations[index];

      if (loc && loc.longitude && loc.latitude) {
        this.map.flyTo({
          center: [loc.longitude, loc.latitude],
          zoom: 10,
          essential: true
        });
      }
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

    const ordered = [...points].reverse();
    const data = [];

    for (let i = 0; i < ordered.length; i++) {
      const curr = ordered[i];
      const currLocs = Array.isArray(curr.locations) ? curr.locations : [];

      // 1) Intra-post segments: every consecutive pair inside the same post
      for (let j = 0; j < currLocs.length - 1; j++) {
        const a = currLocs[j];
        const b = currLocs[j + 1];
        if (!a || !b) continue;

        const from = [a.longitude, a.latitude];
        const to   = [b.longitude, b.latitude];

        data.push({
          coordinates: [from, to],
          bearing: this.getBearing(from, to),
          // If travel type belongs to the "arrival" location, use b.travelType.
          travelType: b?.travelType ?? a?.travelType ?? null,
        });
      }

      // 2) Inter-post segment: last of current → first of next
      if (i < ordered.length - 1) {
        const next = ordered[i + 1];
        const nextLocs = Array.isArray(next.locations) ? next.locations : [];

        const lastCurr = currLocs[currLocs.length - 1];
        const firstNext = nextLocs[0];

        if (lastCurr && firstNext) {
          const from = [lastCurr.longitude, lastCurr.latitude];
          const to   = [firstNext.longitude, firstNext.latitude];

          data.push({
            coordinates: [from, to],
            bearing: this.getBearing(from, to),
            // Travel type associated with the next point/arrival, per your original code
            travelType: firstNext?.travelType ?? null,
          });
        }
      }
    }

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