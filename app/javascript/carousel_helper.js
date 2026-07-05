const initializedCarousels = new WeakSet()

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

  carousel.querySelectorAll("img").forEach(image => {
    image.addEventListener("load", updateHeight)
    if (image.complete) updateHeight()
  })

  carousel.querySelectorAll("video").forEach(video => {
    video.addEventListener("loadedmetadata", updateHeight)
  })

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
