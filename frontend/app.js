/**
 * ==============================================================================
 * Smart Environmental Sensing System (ESS) - Main Application Orchestrator
 * Bengkel Mekatronika Politeknik Kota Malang (POLTEKOM)
 * Modular Architecture (TD-F01 Selesai - Pilar 3 Compliance: < 70 baris)
 * Komponen: carousel.js, node_selector.js, sparkline.js, telemetry.js, chat.js
 * ==============================================================================
 */

// --- 1. SCROLL MORPHING CONTROLLER (Hero State <-> Scrolled Split-View) ---
function initScrollMorphing() {
  const section = document.getElementById('workspaceSection');
  if (!section) return;

  let isTicking = false;
  const onScroll = () => {
    const scrollY = window.scrollY || window.pageYOffset;
    if (scrollY > 70) {
      if (!section.classList.contains('scrolled-layout')) {
        section.classList.remove('hero-layout');
        section.classList.add('scrolled-layout');
        // Redraw canvas sparklines saat drawer kolom melebar
        setTimeout(() => {
          if (typeof renderAllSparklines === 'function') renderAllSparklines();
        }, 200);
      }
    } else if (scrollY < 30) {
      if (!section.classList.contains('hero-layout')) {
        section.classList.remove('scrolled-layout');
        section.classList.add('hero-layout');
      }
    }
    isTicking = false;
  };

  window.addEventListener('scroll', () => {
    if (!isTicking) {
      window.requestAnimationFrame(onScroll);
      isTicking = true;
    }
  }, { passive: true });

  onScroll();
}

// --- 2. RESIZE LISTENER ---
window.addEventListener('resize', () => {
  if (typeof renderAllSparklines === 'function') {
    renderAllSparklines();
  }
});

// --- 3. INITIALIZATION ON DOM READY ---
document.addEventListener("DOMContentLoaded", () => {
  // 1. Inisialisasi Carousel foto kampus
  if (typeof restartSlideTimer === 'function') restartSlideTimer();

  // 2. Inisialisasi Scroll Morphing
  initScrollMorphing();

  // 3. Render awal metrik & canvas sparklines
  if (typeof applyDisplay === 'function' && typeof currentSensorState !== 'undefined') {
    applyDisplay(currentSensorState);
  }
  if (typeof renderAllSparklines === 'function') {
    renderAllSparklines();
  }

  // 4. Ambil daftar node dari Supabase
  if (typeof fetchRegisteredNodes === 'function') {
    fetchRegisteredNodes();
  }

  // 5. Mulai stream telemetri Firebase RTDB
  if (typeof fetchLatestTelemetry === 'function') {
    fetchLatestTelemetry();
    const interval = (typeof CONFIG !== 'undefined' && CONFIG.POLL_INTERVAL) ? CONFIG.POLL_INTERVAL : 2500;
    setInterval(fetchLatestTelemetry, interval);
  }

  console.log("🏭 [ESS POLTEKOM] Modular dashboard engine initialized successfully!");
});
