const initializedCarousels = new WeakSet()
const enqueuedImages = new WeakSet()
const preloadQueue = []
const maxConcurrentPreloads = 2
let activePreloads = 0
let preloadTimer = null

const mediaContainerFor = image => image.closest(".post-media")
const loaderFor = image => mediaContainerFor(image)?.querySelector(".post-media__loader")

const markImageLoading = image => {
  if (image.complete) return

  mediaContainerFor(image)?.classList.add("post-media--image-loading")
  loaderFor(image)?.classList.remove("visually-hidden")
}

const markImageLoaded = image => {
  mediaContainerFor(image)?.classList.remove("post-media--image-loading")
  loaderFor(image)?.classList.add("visually-hidden")
}

const initializeImageLoadingState = image => {
  if (image.complete) {
    markImageLoaded(image)
    return
  }

  markImageLoading(image)
  image.addEventListener("load", () => markImageLoaded(image), { once: true })
  image.addEventListener("error", () => markImageLoaded(image), { once: true })
}

const showSlideImageLoadingState = slide => {
  slide?.querySelectorAll("img").forEach(image => {
    if (image.complete) {
      markImageLoaded(image)
    } else {
      image.loading = "eager"
      markImageLoading(image)
    }
  })
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

  const updateHeight = () => {
    requestAnimationFrame(() => {
      const activeItem = inner.querySelector(".carousel-item.active")
      if (!activeItem) return

      const activeHeight = activeItem.offsetHeight
      if (activeHeight > 0) inner.style.height = `${activeHeight}px`
    })
  }

  carousel.addEventListener("slid.bs.carousel", updateHeight)
  carousel.addEventListener("slide.bs.carousel", event => showSlideImageLoadingState(event.relatedTarget))

  carousel.querySelectorAll("img").forEach(image => {
    initializeImageLoadingState(image)
    image.addEventListener("load", updateHeight)
    if (image.complete) updateHeight()
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
