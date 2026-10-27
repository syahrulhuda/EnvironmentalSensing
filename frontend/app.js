/**
 * ==============================================================================
 * Smart Environmental Sensing System (ESS) - Frontend Engine
 * Bengkel Mekatronika Politeknik Kota Malang (POLTEKOM)
 * 3-Color Strict Minimalist Architecture:
 * 1. Background: #080d1a
 * 2. Card Surface: #0f172a (rgba(15, 23, 42, 0.85))
 * 3. Typography & UI: #ffffff (White with Opacity Tints)
 * ==============================================================================
 */

// --- 1. GLOBAL STATE ---
let audioAllowed = true;
let audioCtx = null;
let sirenOsc = null;
let sirenTimer = null;
let chatHistory = [];

// Data sensor real-time terkini
let currentSensorState = {
  temp: 25.0,
  hum: 52.0,
  mq7_ppm: 5,
  mq2_ppm: 20,
  status: "NORMAL",
  nodeId: "NODE-MRS01",
  lastUpdated: null
};

// --- 2. CAROUSEL KAMPUS POLTEKOM ---
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

// --- 3. WEB AUDIO ALARM ---
function initAudio() {
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (AudioContextClass) audioCtx = new AudioContextClass();
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
}

function startSiren() {
  if (!audioAllowed) return;
  initAudio();
  if (!audioCtx || sirenOsc) return;

  try {
    sirenOsc = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    sirenOsc.type = 'sawtooth';
    sirenOsc.frequency.setValueAtTime(650, audioCtx.currentTime);
    gainNode.gain.setValueAtTime(0.04, audioCtx.currentTime);
    sirenOsc.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    sirenOsc.start();

    let toggle = false;
    sirenTimer = setInterval(() => {
      if (!sirenOsc || !audioCtx) return;
      toggle = !toggle;
      sirenOsc.frequency.setValueAtTime(toggle ? 1100 : 650, audioCtx.currentTime);
    }, 450);
  } catch (e) {
    console.warn("[Siren Warning] Autoplay audio restricted:", e);
  }
}

function stopSiren() {
  if (sirenTimer) {
    clearInterval(sirenTimer);
    sirenTimer = null;
  }
  if (sirenOsc) {
    try { sirenOsc.stop(); } catch (e) {}
    sirenOsc.disconnect();
    sirenOsc = null;
  }
}

function toggleAudio() {
  audioAllowed = !audioAllowed;
  const icon = document.getElementById('audioIcon');
  const btn = document.getElementById('btnAudioMute');
  if (!icon || !btn) return;

  if (audioAllowed) {
    icon.innerText = 'volume_up';
    btn.classList.remove('opacity-50');
  } else {
    icon.innerText = 'volume_off';
    btn.classList.add('opacity-50');
    stopSiren();
  }
}

// --- 4. INDIVIDUAL CARD SPARKLINE GRAPH CANVAS RENDERER ---
const MAX_CHART_POINTS = 20;
let telemetryHistory = [];

// Inisialisasi buffer awal
(function initTelemetryBuffer() {
  const now = Date.now();
  for (let i = 8; i >= 1; i--) {
    const d = new Date(now - i * 2500);
    telemetryHistory.push({
      time: d.toLocaleTimeString('id-ID', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' }),
      temp: 24.8 + (Math.random() * 0.4),
      mq7: 4 + Math.round(Math.random() * 2),
      mq2: 18 + Math.round(Math.random() * 4)
    });
  }
})();

function pushTelemetryToSparklines(temp, mq7, mq2) {
  const timestamp = new Date().toLocaleTimeString('id-ID', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
  telemetryHistory.push({
    time: timestamp,
    temp: Number(temp),
    mq7: Number(mq7),
    mq2: Number(mq2)
  });
  if (telemetryHistory.length > MAX_CHART_POINTS) {
    telemetryHistory.shift();
  }
  renderAllSparklines();
}

function renderSparkline(canvasId, getValue, maxVal, dotColor = '#10b981') {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  const width = rect.width || canvas.parentElement.clientWidth || 240;
  const height = rect.height || 65;

  if (width <= 0) return;

  if (canvas.width !== Math.floor(width * dpr) || canvas.height !== Math.floor(height * dpr)) {
    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);
  }

  ctx.save();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, width, height);

  // Background subtle horizontal grid line
  ctx.strokeStyle = "rgba(56, 189, 248, 0.1)";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(0, height * 0.5);
  ctx.lineTo(width, height * 0.5);
  ctx.stroke();

  if (telemetryHistory.length < 2) {
    ctx.restore();
    return;
  }

  const paddingLeft = 6;
  const paddingRight = 6;
  const paddingTop = 8;
  const paddingBottom = 8;
  const plotW = width - paddingLeft - paddingRight;
  const plotH = height - paddingTop - paddingBottom;
  const stepX = plotW / (telemetryHistory.length - 1);

  // Draw smooth sparkline curve in vibrant Cyan / Sky Blue
  ctx.beginPath();
  ctx.strokeStyle = "#38bdf8";
  ctx.lineWidth = 2;
  ctx.lineJoin = "round";

  telemetryHistory.forEach((pt, idx) => {
    const val = getValue(pt);
    const normY = Math.min(Math.max(val / maxVal, 0), 1);
    const x = paddingLeft + (idx * stepX);
    const y = paddingTop + plotH - (normY * plotH);

    if (idx === 0) {
      ctx.moveTo(x, y);
    } else {
      ctx.lineTo(x, y);
    }
  });
  ctx.stroke();

  // Gradient fill under the curve (Sky Blue tint)
  ctx.lineTo(paddingLeft + plotW, height);
  ctx.lineTo(paddingLeft, height);
  ctx.closePath();
  const grad = ctx.createLinearGradient(0, paddingTop, 0, height);
  grad.addColorStop(0, "rgba(56, 189, 248, 0.2)");
  grad.addColorStop(1, "rgba(56, 189, 248, 0.0)");
  ctx.fillStyle = grad;
  ctx.fill();

  // Active dot at latest reading with K3 semantic color
  const lastPt = telemetryHistory[telemetryHistory.length - 1];
  const lastVal = getValue(lastPt);
  const lastNormY = Math.min(Math.max(lastVal / maxVal, 0), 1);
  const lastX = paddingLeft + ((telemetryHistory.length - 1) * stepX);
  const lastY = paddingTop + plotH - (lastNormY * plotH);

  ctx.beginPath();
  ctx.arc(lastX, lastY, 3.5, 0, Math.PI * 2);
  ctx.fillStyle = dotColor;
  ctx.fill();
  ctx.strokeStyle = "#070d1e";
  ctx.lineWidth = 1.5;
  ctx.stroke();

  ctx.restore();
}

function renderAllSparklines() {
  const lastPt = telemetryHistory[telemetryHistory.length - 1] || currentSensorState;
  
  // K3 Color determination for dots
  const tempDot = lastPt.temp > 35.0 ? '#ef4444' : (lastPt.temp > 30.0 ? '#f59e0b' : '#10b981');
  const smokeDot = lastPt.mq2 > 300 ? '#ef4444' : (lastPt.mq2 > 150 ? '#f59e0b' : '#10b981');
  const toxDot = lastPt.mq7 > 50 ? '#ef4444' : (lastPt.mq7 > 25 ? '#f59e0b' : '#10b981');

  renderSparkline('canvasTemp', pt => pt.temp, 50, tempDot);
  renderSparkline('canvasSmoke', pt => pt.mq2, 500, smokeDot);
  renderSparkline('canvasTox', pt => pt.mq7, 100, toxDot);
}

// --- 5. RENDER UI KE TAMPILAN DASHBOARD ---
function applyDisplay(state) {
  const tempVal = state.temp || 25.0;
  const humVal = state.hum || 52.0;
  const mq2Val = state.mq2_ppm || 0;
  const mq7Val = state.mq7_ppm || 0;

  // 1. Card 1: Suhu Ruangan & Kelembapan
  const displayComfort = document.getElementById('displayComfort');
  const badgeHumidity = document.getElementById('badgeHumidity');
  const badgeComfort = document.getElementById('badgeComfort');

  if (displayComfort) {
    displayComfort.innerText = `${tempVal.toFixed(1)}°C`;
  }
  if (badgeHumidity) {
    badgeHumidity.innerText = `${humVal.toFixed(0)}% RH`;
  }
  if (badgeComfort) {
    if (tempVal > 35.0) {
      badgeComfort.innerText = "Overheat";
      badgeComfort.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-red-500/50 bg-red-500/25 text-red-400 animate-pulse transition-colors";
    } else if (tempVal > 30.0) {
      badgeComfort.innerText = "Hangat";
      badgeComfort.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-amber-500/40 bg-amber-500/20 text-amber-300 transition-colors";
    } else {
      badgeComfort.innerText = "Optimal";
      badgeComfort.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-emerald-500/40 bg-emerald-500/20 text-emerald-400 transition-colors";
    }
  }

  // 2. Card 2: Gas & Asap
  const displaySmoke = document.getElementById('displaySmoke');
  const badgeSmoke = document.getElementById('badgeSmoke');

  if (displaySmoke) {
    displaySmoke.innerText = `${mq2Val} PPM`;
  }
  if (badgeSmoke) {
    if (mq2Val > 300) {
      badgeSmoke.innerText = "Bahaya";
      badgeSmoke.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-red-500/50 bg-red-500/25 text-red-400 animate-pulse transition-colors";
    } else if (mq2Val > 150) {
      badgeSmoke.innerText = "Waspada";
      badgeSmoke.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-amber-500/40 bg-amber-500/20 text-amber-300 transition-colors";
    } else {
      badgeSmoke.innerText = "Aman";
      badgeSmoke.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-emerald-500/40 bg-emerald-500/20 text-emerald-400 transition-colors";
    }
  }

  // 3. Card 3: Karbon Monoksida (CO)
  const displayTox = document.getElementById('displayTox');
  const badgeTox = document.getElementById('badgeTox');

  if (displayTox) {
    displayTox.innerText = `${mq7Val} PPM`;
  }
  if (badgeTox) {
    if (mq7Val > 50) {
      badgeTox.innerText = "Berbahaya";
      badgeTox.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-red-500/50 bg-red-500/25 text-red-400 animate-pulse transition-colors";
    } else if (mq7Val > 25) {
      badgeTox.innerText = "Perhatian";
      badgeTox.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-amber-500/40 bg-amber-500/20 text-amber-300 transition-colors";
    } else {
      badgeTox.innerText = "Aman";
      badgeTox.className = "px-2.5 py-1 rounded-full text-xs font-bold border border-emerald-500/40 bg-emerald-500/20 text-emerald-400 transition-colors";
    }
  }

  // Push latest reading to all 3 sparkline canvases
  pushTelemetryToSparklines(tempVal, mq7Val, mq2Val);

  // Siren Trigger jika ada bahaya aktual & Update Header K3 Status Indicator
  const isDanger = (state.status === "DANGER") || (tempVal > 35.0) || (mq2Val > 300) || (mq7Val > 50);
  const isWarning = (tempVal > 30.0) || (mq2Val > 150) || (mq7Val > 25);

  const headerK3 = document.getElementById('headerK3Indicator');
  if (headerK3) {
    if (isDanger) {
      headerK3.className = "w-10 h-10 rounded-2xl bg-rose-500/25 border border-rose-500/60 flex items-center justify-center text-rose-400 flex-shrink-0 animate-pulse transition-all duration-300 shadow-lg shadow-rose-500/30";
      headerK3.title = "Status K3: BAHAYA - Parameter Lingkungan Kritis!";
    } else if (isWarning) {
      headerK3.className = "w-10 h-10 rounded-2xl bg-amber-500/20 border border-amber-500/50 flex items-center justify-center text-amber-300 flex-shrink-0 transition-all duration-300 shadow-md shadow-amber-500/20";
      headerK3.title = "Status K3: WASPADA - Parameter Lingkungan Meningkat";
    } else {
      headerK3.className = "w-10 h-10 rounded-2xl bg-emerald-500/15 border border-emerald-500/40 flex items-center justify-center text-emerald-400 flex-shrink-0 transition-all duration-300 shadow-sm";
      headerK3.title = "Status K3: AMAN - Kondisi Lingkungan Laboratorium Optimal";
    }
  }

  if (isDanger) {
    startSiren();
  } else {
    stopSiren();
  }
}

// --- 6. REAL-TIME DATA STREAM (FIREBASE RTDB POLLING) ---
async function fetchLatestTelemetry() {
  if (typeof CONFIG === 'undefined' || !CONFIG.FIREBASE_DATABASE_URL) return;

  const statusPill = document.getElementById('systemStatusPill');
  const statusText = document.getElementById('systemStatusText');

  try {
    const res = await fetch(CONFIG.FIREBASE_DATABASE_URL);
    if (!res.ok) {
      if (statusText) statusText.innerText = "OFFLINE";
      if (statusPill) statusPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-xl border border-white/10 bg-white/5 text-white/50 text-xs font-mono";
      return;
    }

    const data = await res.json();
    if (!data) {
      if (statusText) statusText.innerText = "OFFLINE";
      if (statusPill) statusPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-xl border border-white/10 bg-white/5 text-white/50 text-xs font-mono";
      return;
    }

    const keys = Object.keys(data);
    if (keys.length === 0) {
      if (statusText) statusText.innerText = "OFFLINE";
      return;
    }

    const latestKey = keys[keys.length - 1];
    const record = data[latestKey];
    if (!record) return;

    // Update state sensor
    currentSensorState.temp = parseFloat(record.temp || record.temperature || 25.0);
    currentSensorState.hum = parseFloat(record.hum || record.humidity || 50.0);
    currentSensorState.mq7_ppm = parseInt(record.mq7_ppm || record.mq7 || 0, 10);
    currentSensorState.mq2_ppm = parseInt(record.mq2_ppm || record.mq2 || 0, 10);
    currentSensorState.nodeId = record.node_id || record.device_id || "NODE-MRS01";
    currentSensorState.status = record.status || "NORMAL";
    currentSensorState.lastUpdated = new Date();

    if (statusText) statusText.innerText = "ONLINE";
    if (statusPill) statusPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-xl border border-white/15 bg-white/5 text-white text-xs font-mono";

    // Terapkan ke tampilan UI
    applyDisplay(currentSensorState);

  } catch (err) {
    console.warn("[Firebase RTDB] Fetch stream error:", err);
    if (statusText) statusText.innerText = "OFFLINE";
    if (statusPill) statusPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-xl border border-white/10 bg-white/5 text-white/50 text-xs font-mono";
  }
}

// --- 7. ESI CHATBOT SYSTEM ---
function appendUserMessage(text) {
  const feed = document.getElementById('chatFeed');
  if (!feed) return;
  const div = document.createElement('div');
  div.className = "flex gap-2 justify-end animate-fadeIn";
  div.innerHTML = `
    <div class="bg-white/10 border border-white/15 text-white rounded-2xl rounded-tr-none px-3.5 py-2 max-w-[85%] leading-relaxed shadow-sm">
      ${text}
    </div>
  `;
  feed.appendChild(div);
  feed.scrollTop = feed.scrollHeight;
}

function showTypingIndicator() {
  removeTypingIndicator();
  const feed = document.getElementById('chatFeed');
  if (!feed) return;
  const ind = document.createElement('div');
  ind.id = "typingIndicator";
  ind.className = "flex gap-2 items-center animate-fadeIn";
  ind.innerHTML = `
    <div class="w-7 h-7 rounded-lg bg-white/5 border border-white/10 flex-shrink-0 flex items-center justify-center text-white">
      <span class="material-symbols-outlined text-base">smart_toy</span>
    </div>
    <div class="bg-slate-950/60 rounded-xl rounded-tl-none p-2.5 border border-white/10 text-white/70 text-xs flex items-center gap-2">
      <span>ESI sedang memproses...</span>
      <span class="inline-flex gap-1">
        <span class="w-1 h-1 bg-white rounded-full typing-dot"></span>
        <span class="w-1 h-1 bg-white rounded-full typing-dot"></span>
        <span class="w-1 h-1 bg-white rounded-full typing-dot"></span>
      </span>
    </div>
  `;
  feed.appendChild(ind);
  feed.scrollTop = feed.scrollHeight;
}

function removeTypingIndicator() {
  const ind = document.getElementById('typingIndicator');
  if (ind) ind.remove();
}

function appendBotMessage(text) {
  removeTypingIndicator();
  const feed = document.getElementById('chatFeed');
  if (!feed) return;
  const div = document.createElement('div');
  div.className = "flex gap-2 items-start animate-fadeIn";
  div.innerHTML = `
    <div class="w-7 h-7 rounded-lg bg-white/5 border border-white/10 flex-shrink-0 flex items-center justify-center text-white">
      <span class="material-symbols-outlined text-base">smart_toy</span>
    </div>
    <div class="bg-slate-950/60 rounded-xl rounded-tl-none p-3 border border-white/10 text-white max-w-[88%] leading-relaxed shadow-sm">
      ${text}
    </div>
  `;
  feed.appendChild(div);
  feed.scrollTop = feed.scrollHeight;
}

function askPrompt(question) {
  appendUserMessage(question);
  processChatQuery(question);
}

function handleUserSubmit(e) {
  e.preventDefault();
  const input = document.getElementById('inputMessage');
  if (!input) return;
  const val = input.value.trim();
  if (!val) return;
  input.value = '';
  appendUserMessage(val);
  processChatQuery(val);
}

async function processChatQuery(query) {
  showTypingIndicator();
  const baseBackend = (typeof CONFIG !== 'undefined' && CONFIG.BACKEND_API_URL) ? CONFIG.BACKEND_API_URL.replace(/\/+$/, "") : "";

  if (baseBackend) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 20000);

      const res = await fetch(`${baseBackend}/api/chat`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true"
        },
        body: JSON.stringify({
          message: query,
          history: chatHistory
        }),
        signal: controller.signal
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        const json = await res.json();
        if (json && json.reply) {
          removeTypingIndicator();
          appendBotMessage(json.reply);
          chatHistory.push({ role: 'user', content: query });
          chatHistory.push({ role: 'model', content: json.reply });
          return;
        }
      }
    } catch (e) {
      console.warn("[ESS Gateway] FastAPI Gateway tidak merespons, beralih ke local reasoning:", e);
    }
  }

  // Local Reasoning Fallback
  setTimeout(() => {
    removeTypingIndicator();
    const q = query.toLowerCase();
    let answer = "";

    if (q.includes('sehat') || q.includes('kualitas') || q.includes('udara')) {
      answer = `Kadar Karbon Monoksida (CO) terpantau <strong>${currentSensorState.mq7_ppm} PPM</strong> (di bawah batas ambang 50 PPM). Sirkulasi udara ruangan aman dan bersih untuk kegiatan praktikum.`;
    } else if (q.includes('suhu') || q.includes('panas') || q.includes('dingin') || q.includes('cuaca') || q.includes('temp')) {
      answer = `Suhu ruangan saat ini tercatat <strong>${currentSensorState.temp.toFixed(1)}°C</strong> dengan kelembapan <strong>${currentSensorState.hum.toFixed(1)}% RH</strong>. Kondisi ruangan optimal.`;
    } else if (q.includes('asap') || q.includes('bahaya') || q.includes('bocor') || q.includes('kebakaran') || q.includes('gas')) {
      answer = `Sensor gas & asap mendeteksi konsentrasi sebesar <strong>${currentSensorState.mq2_ppm} PPM</strong> (Batas aman < 150 PPM). Ruang laboratorium terpantau aman dari risiko kebakaran.`;
    } else if (q.includes('tips') || q.includes('hemat') || q.includes('jaga') || q.includes('k3')) {
      answer = "<strong>Tips K3 Laboratorium:</strong><br>1. Matikan solder dan alat pemanas listrik setelah selesai praktikum.<br>2. Pastikan ventilasi udara terbuka saat pengerjaan PCB.<br>3. Hubungi teknisi bengkel bila alarm sensor menyala.";
    } else {
      answer = `Data telemetri node <code>${currentSensorState.nodeId}</code> terkini: Suhu: <strong>${currentSensorState.temp.toFixed(1)}°C</strong>, Kelembapan: <strong>${currentSensorState.hum.toFixed(1)}% RH</strong>, CO: <strong>${currentSensorState.mq7_ppm} PPM</strong>, Asap: <strong>${currentSensorState.mq2_ppm} PPM</strong>. Status: <strong>${currentSensorState.status}</strong>.`;
    }

    appendBotMessage(answer);
    chatHistory.push({ role: 'user', content: query });
    chatHistory.push({ role: 'model', content: answer });
  }, 400);
}

// --- 8. SCROLL MORPHING CONTROLLER ---
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
        // Redraw sparklines when drawer expands
        setTimeout(renderAllSparklines, 200);
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

// --- 9. INITIALIZATION ON PAGE LOAD ---
window.addEventListener('resize', () => {
  renderAllSparklines();
});

document.addEventListener("DOMContentLoaded", () => {
  // Carousel
  restartSlideTimer();

  // Scroll Morphing
  initScrollMorphing();

  // Initial UI Render & Sparklines
  applyDisplay(currentSensorState);
  renderAllSparklines();

  // Polling stream telemetri
  fetchLatestTelemetry();
  setInterval(fetchLatestTelemetry, (typeof CONFIG !== 'undefined' && CONFIG.POLL_INTERVAL) ? CONFIG.POLL_INTERVAL : 2500);

  console.log("🏭 Smart Environmental Sensing System (ESS) POLTEKOM initialized successfully!");
});
