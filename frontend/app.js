/**
 * ==============================================================================
 * Smart Environmental Sensing System (ESS) - Main Application Orchestrator
 * Bengkel Mekatronika Politeknik Kota Malang (POLTEKOM)
 * Modular Architecture (TD-F01 Selesai - Pilar 3 Compliance: < 70 baris)
 * Komponen: carousel.js, node_selector.js, sparkline.js, telemetry.js, chat.js
 * ==============================================================================
 */

// --- 1. SCROLL MORPHING & SMART HEADER CONTROLLER ---
function initScrollMorphing() {
  const section = document.getElementById('workspaceSection');
  const header = document.getElementById('mainHeader');
  const fab = document.getElementById('esiFabContainer');
  if (!section) return;

  let isTicking = false;

  const onScroll = () => {
    const scrollY = window.scrollY || window.pageYOffset;

    // 1. Layout Morphing (Hero State <-> Scrolled Split-View)
    if (scrollY > 60) {
      if (!section.classList.contains('scrolled-layout')) {
        section.classList.remove('hero-layout');
        section.classList.add('scrolled-layout');
        // Redraw canvas sparklines saat drawer kolom melebar
        setTimeout(() => {
          if (typeof renderAllSparklines === 'function') renderAllSparklines();
        }, 200);
      }
      if (fab) fab.classList.add('fab-hidden');
    } else if (scrollY < 25) {
      if (!section.classList.contains('hero-layout')) {
        section.classList.remove('scrolled-layout');
        section.classList.add('hero-layout');
      }
      if (fab) fab.classList.remove('fab-hidden');
    }

    // 2. Deterministic Header Auto-Hide on Scroll Down
    if (header) {
      if (scrollY > 50) {
        header.classList.add('header-hidden');
      } else {
        header.classList.remove('header-hidden');
      }
    }

    // 3. Dynamic ESI Chat Card Height Resizing (Clamped Above Footer)
    updateDynamicChatCardHeight();

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

// --- 2. DYNAMIC RESPONSIVE ESI CHAT CARD HEIGHT CONTROLLER ---
function updateDynamicChatCardHeight() {
  const section = document.getElementById('workspaceSection');
  const chatCard = document.getElementById('esiChatCard');
  const footer = document.querySelector('footer');
  const cardsCol = document.getElementById('cardsColumn');

  if (!section || !chatCard) return;

  // Hanya terapkan dynamic resize pada layar desktop (>= 992px) saat scrolled-layout aktif
  if (window.innerWidth >= 992 && section.classList.contains('scrolled-layout')) {
    const topOffset = 16; // 1rem sticky top
    const bottomGap = 16; // 1rem gap di atas footer
    const viewportHeight = window.innerHeight;

    let bottomLimit = viewportHeight - bottomGap;

    // Jika footer masuk ke viewport, sesuaikan batas bawah agar card berhenti pas di atas footer
    if (footer) {
      const footerRect = footer.getBoundingClientRect();
      if (footerRect.top < viewportHeight) {
        bottomLimit = footerRect.top - bottomGap;
      }
    }

    // Ruang vertikal maksimal yang tersedia di viewport
    const maxAvailableH = bottomLimit - topOffset;

    // Tinggi ideal: sejajar dengan cardsColumn di kiri atau memenuhi viewport
    const cardsHeight = cardsCol ? cardsCol.offsetHeight : 580;
    const idealHeight = Math.min(cardsHeight, viewportHeight - topOffset - bottomGap);

    // Dynamic height = minimum idealHeight dan maxAvailableH, clamped minimal 320px
    const targetH = Math.max(320, Math.min(idealHeight, maxAvailableH));

    chatCard.style.height = `${targetH}px`;
  } else {
    chatCard.style.height = '';
  }
}

// --- 3. FLOATING ACTION BUTTON (FAB) ESI HANDLER ---
function openEsiFromFab() {
  const chatSection = document.getElementById('chatColumn') || document.getElementById('workspaceSection');
  if (chatSection) {
    const targetY = chatSection.getBoundingClientRect().top + window.pageYOffset - 90;
    window.scrollTo({ top: Math.max(140, targetY), behavior: 'smooth' });
  } else {
    window.scrollTo({ top: 380, behavior: 'smooth' });
  }
  // Otomatis fokus ke input chat agar user langsung bisa mengetik
  setTimeout(() => {
    const input = document.getElementById('inputMessage');
    if (input) input.focus();
  }, 450);
}

// --- 4. RESIZE LISTENER ---
window.addEventListener('resize', () => {
  if (typeof renderAllSparklines === 'function') {
    renderAllSparklines();
  }
  updateDynamicChatCardHeight();
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
