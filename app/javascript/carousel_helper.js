document.addEventListener('DOMContentLoaded', () => {
  const carousel = document.querySelector('.carousel');

  if (carousel) {
    const inner = carousel.querySelector('.carousel-inner');

  // Function to update the height of the carousel
  const updateCarouselHeight = () => {
    const activeItem = inner.querySelector('.carousel-item.active');
    if (activeItem) {
      const activeHeight = activeItem.offsetHeight;
      inner.style.height = `${activeHeight}px`;
    }
  };

  // Add a transition effect to the carousel-inner
  inner.style.transition = 'height 0.25s ease';

  // Update height on slide change
  carousel.addEventListener('slid.bs.carousel', updateCarouselHeight);
  }
});