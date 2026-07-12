import { Carousel } from "bootstrap"

const initializedCarousels = new WeakSet()
const enqueuedImages = new WeakSet()
const carouselLoadingImages = new WeakMap()
const preloadQueue = []
const maxConcurrentPreloads = 2
let activePreloads = 0
let preloadTimer = null

const loaderFor = carousel => carousel.querySelector(":scope > .carousel-image-loader")

const showCarouselLoader = (carousel, image) => {
  carouselLoadingImages.set(carousel, image)
  loaderFor(carousel)?.classList.remove("visually-hidden")
}

const hideCarouselLoader = (carousel, image) => {
  if (carouselLoadingImages.get(carousel) !== image) return

  loaderFor(carousel)?.classList.add("visually-hidden")
}

const removeImageSkeleton = image => {
  const finish = () => {
    image.classList.add("post-image--decoded")
    hideCarouselLoader(image.closest(".carousel"), image)
  }

  if (typeof image.decode === "function") {
    image.decode().then(finish, finish)
  } else {
    finish()
  }
}

const prepareSlide = (carousel, slide) => {
  const image = slide?.querySelector("img.post-image")

  if (!image) {
    carouselLoadingImages.delete(carousel)
    loaderFor(carousel)?.classList.add("visually-hidden")
    return
  }

  image.loading = "eager"

  if (image.classList.contains("post-image--decoded")) {
    carouselLoadingImages.set(carousel, image)
    loaderFor(carousel)?.classList.add("visually-hidden")
  } else {
    showCarouselLoader(carousel, image)
  }
}

const schedulePreloadQueue = () => {
  if (preloadTimer) return

  const schedule = window.requestIdleCallback || (callback => window.setTimeout(callback, 250))
  preloadTimer = schedule(() => {
    preloadTimer = null
    processPreloadQueue()
  })
}

const processPreloadQueue = () => {
  while (activePreloads < maxConcurrentPreloads && preloadQueue.length > 0) {
    const image = preloadQueue.shift()
    preloadCarouselImage(image)
  }
}

const preloadCarouselImage = image => {
  if (!image.isConnected || image.complete) {
    schedulePreloadQueue()
    return
  }

  activePreloads += 1

  const preload = new Image()

  const finish = () => {
    activePreloads -= 1
    window.setTimeout(processPreloadQueue, 150)
  }

  preload.addEventListener("load", finish, { once: true })
  preload.addEventListener("error", finish, { once: true })
  preload.decoding = "async"
  preload.fetchPriority = "low"
  preload.sizes = image.sizes
  preload.srcset = image.srcset
  preload.src = image.currentSrc || image.src
}

const enqueueCarouselPreloads = carousel => {
  carousel.querySelectorAll("img[data-carousel-preload]").forEach(image => {
    if (enqueuedImages.has(image)) return

    enqueuedImages.add(image)
    preloadQueue.push(image)
  })

  schedulePreloadQueue()
}

const initializeCarousel = carousel => {
  if (initializedCarousels.has(carousel)) return

  const inner = carousel.querySelector(".carousel-inner")
  if (!inner) return

  initializedCarousels.add(carousel)
  Carousel.getOrCreateInstance(carousel)

  const updateHeight = () => {
    requestAnimationFrame(() => {
      const activeItem = inner.querySelector(".carousel-item.active")
      if (!activeItem) return

      const activeHeight = activeItem.offsetHeight
      if (activeHeight > 0) inner.style.height = `${activeHeight}px`
    })
  }

  const activeImage = inner.querySelector(".carousel-item.active img.post-image")
  if (activeImage) {
    showCarouselLoader(carousel, activeImage)
  } else {
    loaderFor(carousel)?.classList.add("visually-hidden")
  }

  carousel.addEventListener("slid.bs.carousel", updateHeight)
  carousel.addEventListener("slide.bs.carousel", event => prepareSlide(carousel, event.relatedTarget))

  carousel.querySelectorAll("img").forEach(image => {
    image.addEventListener("load", updateHeight)
    image.addEventListener("load", () => removeImageSkeleton(image), { once: true })
    image.addEventListener("error", () => removeImageSkeleton(image), { once: true })

    if (image.complete) {
      removeImageSkeleton(image)
      updateHeight()
    }
  })

  carousel.querySelectorAll("video").forEach(video => {
    video.addEventListener("loadedmetadata", updateHeight)
  })

  enqueueCarouselPreloads(carousel)
  updateHeight()
}

const initializeCarousels = () => {
  document.querySelectorAll(".carousel").forEach(initializeCarousel)
}

document.addEventListener("turbo:load", initializeCarousels)
document.addEventListener("turbo:frame-load", initializeCarousels)

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initializeCarousels)
} else {
  initializeCarousels()
}
