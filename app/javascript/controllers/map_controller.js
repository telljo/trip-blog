import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

const MAPTILER_STYLE_URL = "https://api.maptiler.com/maps/hybrid/style.json?key=YceGCelRYIEShW1l58mK"
const ROUTE_ICON_SIZE = 0.55

export default class extends Controller {
  static targets = ["map"]

  connect() {
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
    ;[...tooltipTriggerList].forEach((tooltipTriggerEl) => new Tooltip(tooltipTriggerEl))

    if (!this.hasMapTarget) {
      return
    }

    this.coordinatesMap = {}
    this.currentPostId = null
    this.map = null
    this.handleScroll = this.handleScroll.bind(this)
    this.mapTarget.innerHTML = ""
    this.scheduleMapInitialisation()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)

    if (this.idleCallback) {
      if ("cancelIdleCallback" in window) {
        window.cancelIdleCallback(this.idleCallback)
      } else {
        clearTimeout(this.idleCallback)
      }
    }

    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  scheduleMapInitialisation() {
    const initialise = () => this.initialiseMap()

    if ("requestIdleCallback" in window) {
      this.idleCallback = window.requestIdleCallback(initialise, { timeout: 1000 })
    } else {
      this.idleCallback = setTimeout(initialise, 100)
    }
  }

  async initialiseMap() {
    if (!this.hasMapTarget) {
      return
    }

    const { Map, Marker, Popup, FullscreenControl } = await import("maplibre-gl")
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

    this.map.addControl(new FullscreenControl({ container: document.querySelector("body") }))

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
    window.addEventListener("scroll", this.handleScroll)
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

  handleScroll() {
    const scrollPosition = window.scrollY + window.innerHeight / 2
    let currentPost = null
    this.posts = document.querySelectorAll(".post")

    if (this.posts.length > 0 && this.currentPostId === null) {
      this.currentPostId = this.posts[0].firstElementChild.id.split("_")[1]
    }

    for (const post of this.posts) {
      const postTop = post.offsetTop
      const postBottom = postTop + post.offsetHeight

      if (scrollPosition >= postTop && scrollPosition <= postBottom) {
        const postId = post.id.split("_")[1]
        if (this.currentPostId !== postId) {
          this.currentPostId = postId
          currentPost = post
          break
        }
      }
    }

    if (currentPost && this.coordinatesMap[this.currentPostId]) {
      const [longitude, latitude] = this.coordinatesMap[this.currentPostId]
      this.map.flyTo({
        center: [longitude, latitude],
        zoom: 10,
        essential: true
      })
    }
  }

  moveToMarker(event) {
    const postId = event.target.dataset.postId
    const coordinates = this.coordinatesMap[postId]

    if (coordinates) {
      this.map.flyTo({
        center: coordinates,
        zoom: 10,
        essential: true
      })
    } else {
      console.error(`Coordinates not found for postId: ${postId}`)
    }
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
