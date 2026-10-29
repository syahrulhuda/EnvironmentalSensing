/**
 * ==============================================================================
 * ESS Frontend Component: Campus Carousel
 * Mengelola pergeseran slide foto kampus POLTEKOM dan indikator dot aktif
 * ==============================================================================
 */

let currentSlideIndex = 0;
const totalSlides = 3;
let slideTimer = null;

function updateSlidePosition() {
  const track = document.getElementById('carouselTrack');
  if (track) {
    track.style.transform = `translateX(-${currentSlideIndex * 100}%)`;
  }
  const dots = document.querySelectorAll('.carousel-dot');
  dots.forEach((dot, idx) => {
    if (idx === currentSlideIndex) {
      dot.className = 'carousel-dot w-6 h-2 rounded-full bg-white transition-all duration-300';
    } else {
      dot.className = 'carousel-dot w-2 h-2 rounded-full bg-white/30 hover:bg-white/80 transition-all duration-300';
    }
  });
}

function nextSlide() {
  currentSlideIndex = (currentSlideIndex + 1) % totalSlides;
  updateSlidePosition();
  restartSlideTimer();
}

function prevSlide() {
  currentSlideIndex = (currentSlideIndex - 1 + totalSlides) % totalSlides;
  updateSlidePosition();
  restartSlideTimer();
}

function goToSlide(idx) {
  currentSlideIndex = idx;
  updateSlidePosition();
  restartSlideTimer();
}

function restartSlideTimer() {
  if (slideTimer) clearInterval(slideTimer);
  slideTimer = setInterval(() => {
    currentSlideIndex = (currentSlideIndex + 1) % totalSlides;
    updateSlidePosition();
  }, 5000);
}

// Ekspor ke window global untuk event handler inline HTML
window.nextSlide = nextSlide;
window.prevSlide = prevSlide;
window.goToSlide = goToSlide;
window.restartSlideTimer = restartSlideTimer;
