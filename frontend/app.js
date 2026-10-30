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
  let lastScrollY = window.scrollY || window.pageYOffset;

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

    // 2. Smart Header Auto-Hide on Scroll Down, Reveal Compact on Scroll Up
    if (header) {
      if (scrollY <= 40) {
        // Paling atas: Tampilkan header penuh normal
        header.classList.remove('header-hidden');
        header.classList.remove('header-compact');
      } else if (scrollY > lastScrollY && scrollY > 80) {
        // Scroll KE BAWAH: Sembunyikan header total ke atas agar layar luas & bebas halangan
        header.classList.add('header-hidden');
        header.classList.remove('header-compact');
      } else if (scrollY < lastScrollY) {
        // Scroll KE ATAS: Munculkan slim compact bar dengan lokasi & selector node
        header.classList.remove('header-hidden');
        header.classList.add('header-compact');
      }
    }

    lastScrollY = Math.max(0, scrollY);
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

// --- 2. FLOATING ACTION BUTTON (FAB) ESI HANDLER ---
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
    const input = document.getElementById('chatInput');
    if (input) input.focus();
  }, 450);
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
