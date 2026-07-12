import { Controller } from "@hotwired/stimulus"

const MAPTILER_STYLE_URL = "https://api.maptiler.com/maps/hybrid/style.json?key=YceGCelRYIEShW1l58mK"
const ROUTE_ICON_SIZE = 0.55
const MAP_INITIALISATION_MARGIN = "400px 0px"
const CAMERA_UPDATE_DELAY = 200
const CAMERA_ANIMATION_DURATION = 400

export default class extends Controller {
  static targets = ["map"]

  connect() {
    if (!this.hasMapTarget) {
      return
    }

    this.connected = true
    this.coordinatesMap = {}
    this.currentPostId = null
    this.pendingPostId = null
    this.map = null
    this.fullscreenButton = null
    this.mapTarget.innerHTML = ""
    this.scheduleMapInitialisation()
  }

  disconnect() {
    this.connected = false
    document.removeEventListener("keydown", this.handleFullscreenKeydown, true)
    document.body.classList.remove("trip-map-fullscreen-active")
    this.mapInitialisationObserver?.disconnect()
    this.postObserver?.disconnect()
    this.postMutationObserver?.disconnect()
    clearTimeout(this.cameraUpdateTimer)

    if (this.hasMapTarget) {
      this.mapTarget.classList.remove("trip-map--fullscreen")
    }

    this.fullscreenButton?.remove()
    this.fullscreenButton = null

    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  scheduleMapInitialisation() {
    if (!("IntersectionObserver" in window)) {
      this.initialiseMap()
      return
    }

    this.mapInitialisationObserver = new IntersectionObserver((entries) => {
      if (!entries.some((entry) => entry.isIntersecting)) {
        return
      }

      this.mapInitialisationObserver.disconnect()
      this.initialiseMap()
    }, { rootMargin: MAP_INITIALISATION_MARGIN })

    this.mapInitialisationObserver.observe(this.mapTarget)
  }

  async initialiseMap() {
    if (!this.connected || !this.hasMapTarget || this.map) {
      return
    }

    const { Map, Marker, Popup } = await import("maplibre-gl")

    if (!this.connected || !this.element.isConnected) {
      return
    }

    const mapElement = this.mapTarget
    const points = JSON.parse(mapElement.dataset.points)
    const firstPoint = points[0]

    this.coordinatesMap = points.reduce((acc, point) => {
      acc[point.postId] = [point.longitude, point.latitude]
      return acc
    }, {})

    this.map = new Map({
      container: mapElement,
      style: MAPTILER_STYLE_URL,
      center: [firstPoint.longitude, firstPoint.latitude],
      zoom: 10
    })

    this.addFullscreenButton()

    points.forEach((point) => {
      new Marker()
        .setLngLat([point.longitude, point.latitude])
        .setPopup(new Popup({
          closeButton: false,
          closeOnClick: true,
          closeOnMove: true
        }).setHTML(point.tooltip))
        .addTo(this.map)
    })

    this.addMapLayers(points)
    this.observePosts()
  }

  async initialiseMapImages(points) {
    const images = JSON.parse(this.mapTarget.dataset.images)
    const travelTypes = [...new Set(points.map((point) => point.travelType).filter((travelType) => images[travelType]))]

    await Promise.all(travelTypes.flatMap((travelType) => {
      return ["left", "right"].map(async (direction) => {
        const imageName = `${travelType}-${direction}`

        if (this.map.hasImage(imageName)) {
          return
        }

        const image = await this.map.loadImage(images[travelType][direction])
        this.map.addImage(imageName, image.data)
      })
    }))
  }

  observePosts() {
    if (!("IntersectionObserver" in window)) {
      return
    }

    const activePostMargin = Math.floor(window.innerHeight * 0.45)
    this.postObserver = new IntersectionObserver((entries) => {
      const activeEntry = entries
        .filter((entry) => entry.isIntersecting)
        .sort((first, second) => {
          const viewportCenter = window.innerHeight / 2
          const firstCenter = first.boundingClientRect.top + first.boundingClientRect.height / 2
          const secondCenter = second.boundingClientRect.top + second.boundingClientRect.height / 2

          return Math.abs(firstCenter - viewportCenter) - Math.abs(secondCenter - viewportCenter)
        })[0]

      if (activeEntry) {
        this.scheduleCameraUpdate(activeEntry.target.id.split("_")[1])
      }
    }, { rootMargin: `-${activePostMargin}px 0px` })

    this.element.querySelectorAll(".post").forEach((post) => this.postObserver.observe(post))

    const postsContainer = this.element.querySelector("#posts")
    if (postsContainer) {
      this.postMutationObserver = new MutationObserver(() => {
        this.element.querySelectorAll(".post").forEach((post) => this.postObserver.observe(post))
      })
      this.postMutationObserver.observe(postsContainer, { childList: true, subtree: true })
    }
  }

  scheduleCameraUpdate(postId) {
    if (postId === this.currentPostId || postId === this.pendingPostId || !this.coordinatesMap[postId]) {
      return
    }

    this.pendingPostId = postId
    clearTimeout(this.cameraUpdateTimer)
    this.cameraUpdateTimer = setTimeout(() => {
      const coordinates = this.coordinatesMap[this.pendingPostId]

      if (!this.map || !coordinates) {
        this.pendingPostId = null
        return
      }

      this.map.stop()
      this.map.easeTo({
        center: coordinates,
        zoom: 10,
        duration: CAMERA_ANIMATION_DURATION
      })
      this.currentPostId = this.pendingPostId
      this.pendingPostId = null
    }, CAMERA_UPDATE_DELAY)
  }

  moveToMarker(event) {
    const postId = event.target.dataset.postId
    const coordinates = this.coordinatesMap[postId]

    if (coordinates) {
      clearTimeout(this.cameraUpdateTimer)
      this.pendingPostId = null
      this.map.stop()
      this.map.easeTo({
        center: coordinates,
        zoom: 10,
        duration: CAMERA_ANIMATION_DURATION
      })
      this.currentPostId = postId
    } else {
      console.error(`Coordinates not found for postId: ${postId}`)
    }
  }

  addFullscreenButton() {
    this.fullscreenButton = document.createElement("button")
    this.fullscreenButton.type = "button"
    this.fullscreenButton.className = "btn btn-light shadow-sm trip-map__fullscreen-button"
    this.fullscreenButton.addEventListener("click", () => this.toggleMapFullscreen())

    this.updateFullscreenButton()
    this.mapTarget.appendChild(this.fullscreenButton)
  }

  toggleMapFullscreen() {
    if (this.mapTarget.classList.contains("trip-map--fullscreen")) {
      this.exitMapFullscreen()
    } else {
      this.enterMapFullscreen()
    }
  }

  enterMapFullscreen() {
    this.mapTarget.classList.add("trip-map--fullscreen")
    document.body.classList.add("trip-map-fullscreen-active")
    document.addEventListener("keydown", this.handleFullscreenKeydown, true)
    this.updateFullscreenButton()
    this.resizeMap()
  }

  exitMapFullscreen({ focusButton = false } = {}) {
    this.mapTarget.classList.remove("trip-map--fullscreen")
    document.body.classList.remove("trip-map-fullscreen-active")
    document.removeEventListener("keydown", this.handleFullscreenKeydown, true)
    this.updateFullscreenButton()
    this.resizeMap()

    if (focusButton) {
      this.fullscreenButton?.focus({ preventScroll: true })
    }
  }

  handleFullscreenKeydown = (event) => {
    if (event.key === "Escape" && this.mapTarget.classList.contains("trip-map--fullscreen")) {
      event.preventDefault()
      this.exitMapFullscreen({ focusButton: true })
    }
  }

  updateFullscreenButton() {
    if (!this.fullscreenButton) {
      return
    }

    const isFullscreen = this.mapTarget.classList.contains("trip-map--fullscreen")
    const label = isFullscreen ? "Exit fullscreen map" : "Enter fullscreen map"
    const iconClass = isFullscreen ? "bi-fullscreen-exit" : "bi-arrows-fullscreen"

    this.fullscreenButton.setAttribute("aria-label", label)
    this.fullscreenButton.setAttribute("aria-pressed", isFullscreen.toString())
    this.fullscreenButton.title = label
    this.fullscreenButton.innerHTML = `<i class="bi ${iconClass}" aria-hidden="true"></i>`
  }

  resizeMap() {
    window.requestAnimationFrame(() => {
      this.map?.resize()
    })
  }

  addMapLayers(points) {
    const cacheKey = `mapLayers_${JSON.stringify(points)}`
    const cachedPointData = localStorage.getItem(cacheKey)
    const pointData = cachedPointData ? JSON.parse(cachedPointData) : this.processPointData(points, cacheKey)

    this.map.on("load", async () => {
      await this.initialiseMapImages(points)

      this.map.addSource("route", {
        type: "geojson",
        data: {
          type: "FeatureCollection",
          features: pointData.map((pd) => ({
            type: "Feature",
            properties: {
              travelType: pd.travelType,
              bearing: pd.bearing
            },
            geometry: {
              type: "LineString",
              coordinates: pd.coordinates
            }
          }))
        }
      })

      this.map.addLayer({
        id: "route",
        type: "line",
        source: "route",
        layout: {},
        paint: {
          "line-color": "#FFF",
          "line-width": 2,
          "line-dasharray": [2, 1]
        }
      })

      this.addRouteSymbolLayers([...new Set(pointData.map((point) => point.travelType).filter(Boolean))])
    })
  }

  addRouteSymbolLayers(travelTypes) {
    travelTypes.forEach((travelType) => {
      this.map.addLayer({
        id: `symbol-${travelType}`,
        type: "symbol",
        source: "route",
        layout: {
          "icon-image": [
            "case",
            ["<", ["get", "bearing"], 180],
            `${travelType}-right`,
            `${travelType}-left`
          ],
          "symbol-placement": "line",
          "symbol-spacing": 100,
          "icon-size": ROUTE_ICON_SIZE,
          "icon-rotate": [
            "case",
            ["<", ["get", "bearing"], 180],
            360,
            180
          ]
        },
        filter: ["==", ["get", "travelType"], travelType]
      })
    })
  }

  processPointData(points, cacheKey) {
    const data = [...points].reverse().map((point, index, reversedPoints) => {
      if (index === reversedPoints.length - 1) {
        return
      }

      const nextPoint = reversedPoints[index + 1]
      return {
        coordinates: [
          [point.longitude, point.latitude],
          [nextPoint.longitude, nextPoint.latitude]
        ],
        bearing: this.getBearing([point.longitude, point.latitude], [nextPoint.longitude, nextPoint.latitude]),
        travelType: nextPoint.travelType
      }
    }).filter(Boolean)

    localStorage.setItem(cacheKey, JSON.stringify(data))
    return data
  }

  getBearing(firstCoordinates, secondCoordinates) {
    const toRadians = (degrees) => degrees * (Math.PI / 180)
    const lat1 = toRadians(firstCoordinates[1])
    const lon1 = toRadians(firstCoordinates[0])
    const lat2 = toRadians(secondCoordinates[1])
    const lon2 = toRadians(secondCoordinates[0])

    const y = Math.sin(lon2 - lon1) * Math.cos(lat2)
    const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(lon2 - lon1)
    let brng = Math.atan2(y, x)
    brng = brng * (180 / Math.PI)
    brng = (brng + 360) % 360

    return brng
  }
}
