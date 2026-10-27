/**
 * ==============================================================================
 * Smart Environmental Sensing System (ESS) - Frontend Engine & Data Stream Controller
 * Bengkel Mekatronika Politeknik Kota Malang (POLTEKOM)
 * Mengikuti Konstitusi RULEBOOK.md & Kontrak Arsitektur 5-Layer
 * ==============================================================================
 */

// --- 1. GLOBAL STATE ---
let isSimulatedDanger = false;
let isRealDanger = false;
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
      dot.className = 'carousel-dot w-6 h-2 rounded-full bg-emerald-400 transition-all duration-300';
    } else {
      dot.className = 'carousel-dot w-2 h-2 rounded-full bg-white/40 hover:bg-white/80 transition-all duration-300';
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

// --- 3. WEB AUDIO SIREN ALARM ---
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
    btn.classList.remove('text-red-400', 'border-red-500/40');
    btn.classList.add('text-slate-300');
    if (isSimulatedDanger || isRealDanger) startSiren();
  } else {
    icon.innerText = 'volume_off';
    btn.classList.add('text-red-400', 'border-red-500/40');
    btn.classList.remove('text-slate-300');
    stopSiren();
  }
}

// --- 4. TOGGLE MANUAL SIMULASI BAHAYA ---
function toggleDangerSimulation() {
  isSimulatedDanger = !isSimulatedDanger;
  applyDisplay(currentSensorState);
}

// --- 4.5 TELEMETRY PROGRESSION CHART CANVAS RENDERER ---
const MAX_CHART_POINTS = 20;
let telemetryHistory = [];

// Pre-fill history buffer with initial baseline points
(function initTelemetryBuffer() {
  const now = Date.now();
  for (let i = 6; i >= 1; i--) {
    const d = new Date(now - i * 2500);
    telemetryHistory.push({
      time: d.toLocaleTimeString('id-ID', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' }),
      temp: 24.8 + (Math.random() * 0.4),
      mq7: 4 + Math.round(Math.random() * 2),
      mq2: 18 + Math.round(Math.random() * 4)
    });
  }
})();

function pushTelemetryToChart(temp, mq7, mq2) {
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
  renderTelemetryCanvas();
}

function renderTelemetryCanvas() {
  const canvas = document.getElementById('telemetryChartCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  const width = rect.width || canvas.parentElement.clientWidth || 320;
  const height = rect.height || 140;

  if (canvas.width !== Math.floor(width * dpr) || canvas.height !== Math.floor(height * dpr)) {
    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);
  }

  ctx.save();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, width, height);

  // Background subtle horizontal grid lines
  ctx.strokeStyle = "rgba(255, 255, 255, 0.05)";
  ctx.lineWidth = 1;
  const gridRows = 4;
  for (let i = 0; i <= gridRows; i++) {
    const y = (height / gridRows) * i;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(width, y);
    ctx.stroke();
  }

  if (telemetryHistory.length < 2) {
    ctx.restore();
    return;
  }

  const paddingLeft = 32;
  const paddingRight = 10;
  const paddingTop = 12;
  const paddingBottom = 20;
  const plotW = width - paddingLeft - paddingRight;
  const plotH = height - paddingTop - paddingBottom;
  const stepX = plotW / (telemetryHistory.length - 1);

  function drawSeries(getValue, strokeColor, maxVal) {
    ctx.beginPath();
    ctx.strokeStyle = strokeColor;
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

    // Draw active dot at latest value
    const lastPt = telemetryHistory[telemetryHistory.length - 1];
    const lastVal = getValue(lastPt);
    const lastNormY = Math.min(Math.max(lastVal / maxVal, 0), 1);
    const lastX = paddingLeft + ((telemetryHistory.length - 1) * stepX);
    const lastY = paddingTop + plotH - (lastNormY * plotH);

    ctx.beginPath();
    ctx.arc(lastX, lastY, 3.5, 0, Math.PI * 2);
    ctx.fillStyle = strokeColor;
    ctx.fill();
    ctx.strokeStyle = "#0f172a";
    ctx.lineWidth = 1.5;
    ctx.stroke();
  }

  // 1. Suhu (°C, max 50) -> Primary (Sky Blue #38bdf8)
  drawSeries(pt => pt.temp, "#38bdf8", 50);

  // 2. Asap (PPM, max 500) -> Accent (Emerald #10b981)
  drawSeries(pt => pt.mq2, "#10b981", 500);

  // 3. Karbon Monoksida CO (PPM, max 100) -> Primary tint (Light Sky #93c5fd)
  drawSeries(pt => pt.mq7, "#93c5fd", 100);

  // Y-axis indicators
  ctx.fillStyle = "rgba(148, 163, 184, 0.6)";
  ctx.font = "9px 'JetBrains Mono', monospace";
  ctx.textAlign = "right";
  ctx.fillText("MAX", paddingLeft - 4, paddingTop + 6);
  ctx.fillText("MID", paddingLeft - 4, paddingTop + plotH / 2 + 3);
  ctx.fillText("0", paddingLeft - 4, paddingTop + plotH);

  // X-axis latest timestamp
  const latestTime = telemetryHistory[telemetryHistory.length - 1]?.time || "";
  ctx.textAlign = "right";
  ctx.fillText(latestTime, width - paddingRight, height - 4);

  ctx.restore();
}

// --- 5. RENDER UI KE TAMPILAN DASHBOARD (3-COLOR MINIMALIST PALETTE) ---
function applyDisplay(state) {
  const isDanger = isSimulatedDanger || isRealDanger;

  // Tombol Simulasi
  const btnLabel = document.getElementById('btnDangerLabel');
  const btnIcon = document.getElementById('btnDangerIcon');
  const btnDanger = document.getElementById('btnDangerToggle');
  if (btnLabel && btnIcon && btnDanger) {
    if (isSimulatedDanger) {
      btnLabel.innerText = "Kembalikan Normal";
      btnIcon.innerText = "check_circle";
      btnDanger.className = "group px-4 py-2 rounded-xl bg-red-600 text-white font-semibold text-xs flex items-center gap-2 transition-all shadow-lg shadow-red-600/50 scale-105";
    } else {
      btnLabel.innerText = "Simulasi Status: Bahaya";
      btnIcon.innerText = "emergency_home";
      btnDanger.className = "group px-4 py-2 rounded-xl bg-red-500/15 hover:bg-red-500/25 border border-red-500/35 text-red-200 text-xs font-semibold flex items-center gap-2 transition-all shadow-md active:scale-95";
    }
  }

  // Header System Status Pill
  const statusPill = document.getElementById('systemStatusPill');
  const statusText = document.getElementById('systemStatusText');
  if (statusText) {
    if (isDanger) {
      statusText.innerHTML = '<span class="text-red-400 font-bold">DANGER ALERT</span>';
      if (statusPill) statusPill.className = "hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-red-950/40 border border-red-500/40 text-red-300 text-xs font-medium animate-pulse";
    } else {
      statusText.innerText = "ONLINE";
      if (statusPill) statusPill.className = "hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-emerald-950/40 border border-emerald-500/30 text-emerald-300 text-xs font-medium";
    }
  }

  // Ambient Glow
  const bannerGlow = document.getElementById('bannerGlow');
  if (bannerGlow) {
    bannerGlow.className = isDanger
      ? "absolute -right-16 -top-16 w-80 h-80 bg-red-600/30 rounded-full blur-3xl pointer-events-none transition-colors duration-500"
      : "absolute -right-16 -top-16 w-80 h-80 bg-sky-500/15 rounded-full blur-3xl pointer-events-none transition-colors duration-500";
  }

  const tempVal = isSimulatedDanger ? 41.5 : (state.temp || 25.0);
  const humVal = isSimulatedDanger ? 32.0 : (state.hum || 52.0);
  const mq2Val = isSimulatedDanger ? 1000 : (state.mq2_ppm || 0);
  const mq7Val = isSimulatedDanger ? 150 : (state.mq7_ppm || 0);

  // 1. Card 1: Suhu Ruangan
  const cardComfort = document.getElementById('cardComfort');
  const badgeComfort = document.getElementById('badgeComfort');
  const displayComfort = document.getElementById('displayComfort');
  const badgeHumidity = document.getElementById('badgeHumidity');

  if (displayComfort) {
    displayComfort.innerText = `${tempVal.toFixed(1)}°C`;
    if (tempVal > 35.0) {
      displayComfort.className = "text-2xl font-extrabold text-red-400 tracking-tight";
      if (badgeComfort) {
        badgeComfort.className = "px-2.5 py-1 rounded-full text-xs font-bold bg-red-500/20 text-red-300 border border-red-500/40 animate-pulse";
        badgeComfort.innerText = "Bahaya";
      }
      if (cardComfort) cardComfort.className = "rounded-2xl px-4 py-3 border border-red-500/60 bg-red-950/40 backdrop-blur-md flex items-center justify-between shadow-lg transition-all duration-300";
    } else {
      displayComfort.className = "text-2xl font-extrabold text-white tracking-tight";
      if (badgeComfort) {
        badgeComfort.className = "px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30";
        badgeComfort.innerText = "Optimal";
      }
      if (cardComfort) cardComfort.className = "rounded-2xl px-4 py-3 border border-white/10 bg-slate-900/60 backdrop-blur-md flex items-center justify-between shadow-lg transition-all duration-300 hover:border-sky-400/40";
    }
  }

  if (badgeHumidity) {
    badgeHumidity.innerText = `${humVal.toFixed(0)}% RH`;
  }

  // 2. Card 2: Gas & Asap
  const cardSmoke = document.getElementById('cardSmoke');
  const badgeSmoke = document.getElementById('badgeSmoke');
  const displaySmoke = document.getElementById('displaySmoke');
  const iconSmokeBox = document.getElementById('iconSmokeBox');

  if (displaySmoke) {
    displaySmoke.innerText = `${mq2Val} PPM`;
    if (mq2Val > 300) {
      displaySmoke.className = "text-2xl font-extrabold text-red-400 tracking-tight";
      if (badgeSmoke) {
        badgeSmoke.className = "px-2.5 py-1 rounded-full text-xs font-bold bg-red-500/20 text-red-300 border border-red-500/40 animate-pulse";
        badgeSmoke.innerText = "Bahaya";
      }
      if (iconSmokeBox) {
        iconSmokeBox.className = "w-10 h-10 rounded-xl bg-red-500/20 border border-red-500/40 flex items-center justify-center text-red-400 flex-shrink-0 animate-pulse";
      }
      if (cardSmoke) cardSmoke.className = "rounded-2xl px-4 py-3 border border-red-500/60 bg-red-950/40 backdrop-blur-md flex items-center justify-between shadow-lg transition-all duration-300";
    } else {
      displaySmoke.className = "text-2xl font-extrabold text-white tracking-tight";
      if (badgeSmoke) {
        badgeSmoke.className = "px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30";
        badgeSmoke.innerText = "Aman";
      }
      if (iconSmokeBox) {
        iconSmokeBox.className = "w-10 h-10 rounded-xl bg-sky-500/15 border border-sky-400/30 flex items-center justify-center text-sky-400 flex-shrink-0";
      }
      if (cardSmoke) cardSmoke.className = "rounded-2xl px-4 py-3 border border-white/10 bg-slate-900/60 backdrop-blur-md flex items-center justify-between shadow-lg transition-all duration-300 hover:border-sky-400/40";
    }
  }

  // 3. Card 3: Gas Karbon Monoksida (CO)
  const cardTox = document.getElementById('cardTox');
  const badgeTox = document.getElementById('badgeTox');
  const displayTox = document.getElementById('displayTox');
  const iconToxBox = document.getElementById('iconToxBox');

  if (displayTox) {
    displayTox.innerText = `${mq7Val} PPM`;
    if (mq7Val > 50) {
      displayTox.className = "text-2xl font-extrabold text-red-400 tracking-tight";
      if (badgeTox) {
        badgeTox.className = "px-2.5 py-1 rounded-full text-xs font-bold bg-red-500/20 text-red-300 border border-red-500/40 animate-pulse";
        badgeTox.innerText = "Bahaya";
      }
      if (iconToxBox) {
        iconToxBox.className = "w-10 h-10 rounded-xl bg-red-500/20 border border-red-500/40 flex items-center justify-center text-red-400 flex-shrink-0 animate-pulse";
      }
      if (cardTox) cardTox.className = "rounded-2xl px-4 py-3 border border-red-500/60 bg-red-950/40 backdrop-blur-md flex items-center justify-between shadow-lg transition-all duration-300";
    } else {
      displayTox.className = "text-2xl font-extrabold text-white tracking-tight";
      if (badgeTox) {
        badgeTox.className = "px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30";
        badgeTox.innerText = "Aman";
      }
      if (iconToxBox) {
        iconToxBox.className = "w-10 h-10 rounded-xl bg-sky-500/15 border border-sky-400/30 flex items-center justify-center text-sky-400 flex-shrink-0";
      }
      if (cardTox) cardTox.className = "rounded-2xl px-4 py-3 border border-white/10 bg-slate-900/60 backdrop-blur-md flex items-center justify-between shadow-lg transition-all duration-300 hover:border-sky-400/40";
    }
  }

  // Push latest reading to telemetry progression chart
  pushTelemetryToChart(tempVal, mq7Val, mq2Val);

  // Siren Trigger
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
      if (statusPill) statusPill.className = "hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-slate-800/60 border border-slate-600 text-slate-400 text-xs font-medium";
      return;
    }

    const data = await res.json();
    if (!data) {
      if (statusText) statusText.innerText = "OFFLINE";
      if (statusPill) statusPill.className = "hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-slate-800/60 border border-slate-600 text-slate-400 text-xs font-medium";
      return;
    }

    const keys = Object.keys(data);
    if (keys.length === 0) {
      if (statusText) statusText.innerText = "OFFLINE";
      return;
    }

    // Ambil data terbaru berdasarkan key atau timestamp
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

    // Deteksi bahaya riil dari sensor fisik
    const isOverheat = currentSensorState.temp > (CONFIG.THRESHOLDS?.TEMP_MAX || 35.0);
    const isGasDanger = currentSensorState.mq2_ppm > (CONFIG.THRESHOLDS?.MQ2_MAX || 300);
    const isToxDanger = currentSensorState.mq7_ppm > (CONFIG.THRESHOLDS?.MQ7_MAX || 50);

    isRealDanger = (currentSensorState.status === "DANGER") || isOverheat || isGasDanger || isToxDanger;

    // Terapkan ke tampilan UI
    applyDisplay(currentSensorState);

  } catch (err) {
    console.warn("[Firebase RTDB] Fetch stream error:", err);
    if (statusText && !isSimulatedDanger) statusText.innerText = "OFFLINE";
    if (statusPill && !isSimulatedDanger) statusPill.className = "hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-slate-800/60 border border-slate-600 text-slate-400 text-xs font-medium";
  }
}

// --- 7. ESI (ENVIRONMENTAL SENSING INTELLIGENCE) CHATBOT SYSTEM ---
function appendUserMessage(text) {
  const feed = document.getElementById('chatFeed');
  if (!feed) return;
  const div = document.createElement('div');
  div.className = "flex gap-2 justify-end animate-fadeIn";
  div.innerHTML = `
    <div class="bg-sky-500/25 border border-sky-400/35 text-sky-100 rounded-2xl rounded-tr-none px-4 py-2.5 max-w-[85%] leading-relaxed shadow-sm">
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
  ind.className = "flex gap-3 items-center animate-fadeIn";
  ind.innerHTML = `
    <div class="w-8 h-8 rounded-xl bg-indigo-600/35 border border-indigo-400/30 flex-shrink-0 flex items-center justify-center text-base shadow-sm">🤖</div>
    <div class="bg-slate-900/80 rounded-2xl rounded-tl-none p-3 border border-white/10 text-slate-300 text-xs flex items-center gap-2">
      <span>ESI sedang menganalisis data sensor...</span>
      <span class="inline-flex gap-1">
        <span class="w-1.5 h-1.5 bg-sky-400 rounded-full typing-dot"></span>
        <span class="w-1.5 h-1.5 bg-sky-400 rounded-full typing-dot"></span>
        <span class="w-1.5 h-1.5 bg-sky-400 rounded-full typing-dot"></span>
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
  div.className = "flex gap-3 items-start animate-fadeIn";
  div.innerHTML = `
    <div class="w-8 h-8 rounded-xl bg-indigo-600/35 border border-indigo-400/30 flex-shrink-0 flex items-center justify-center text-base shadow-sm">
      🤖
    </div>
    <div class="bg-slate-900/80 rounded-2xl rounded-tl-none p-3.5 border border-white/10 text-slate-100 max-w-[90%] leading-relaxed shadow-sm">
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

// Terhubung ke Layer 4 FastAPI Gateway (POST /api/chat) dengan timeout 20 detik & payload history
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
    const isDanger = isSimulatedDanger || isRealDanger;
    let answer = "";

    if (q.includes('sehat') || q.includes('kualitas') || q.includes('udara')) {
      if (isDanger) {
        answer = "⚠️ <strong>Status Udara Lab: WASPADA!</strong> Sensor mendeteksi kenaikan partikel asap dan gas di ruangan. Disarankan membuka pintu/jendela atau segera evakuasi ke tempat terbuka.";
      } else {
        answer = `🍃 <strong>Udara Sangat Sehat & Bersih!</strong> Kadar Karbon Monoksida (CO) terpantau <strong>${currentSensorState.mq7_ppm} PPM</strong> (jauh di bawah batas bahaya 50 PPM). Sirkulasi udara ruangan sangat baik untuk kegiatan praktikum.`;
      }
    } else if (q.includes('suhu') || q.includes('panas') || q.includes('dingin') || q.includes('cuaca') || q.includes('temp')) {
      answer = `🌡️ Suhu ruangan saat ini tercatat <strong>${currentSensorState.temp.toFixed(1)}°C</strong> dengan kelembapan <strong>${currentSensorState.hum.toFixed(1)}%</strong>. Suhu ${currentSensorState.temp > 35 ? 'terlalu panas' : 'sejuk dan optimal'} untuk ruangan laboratorium.`;
    } else if (q.includes('asap') || q.includes('bahaya') || q.includes('bocor') || q.includes('kebakaran') || q.includes('gas')) {
      if (isDanger) {
        answer = `🚨 <strong>PERINGATAN BAHAYA:</strong> Sensor MQ-2 mendeteksi konsentrasi asap/gas sebesar <strong>${currentSensorState.mq2_ppm} PPM</strong>! Segera periksa sumber panas, kompor solder, atau tabung gas.`;
      } else {
        answer = `🛡️ <strong>Alhamdulillah aman!</strong> Sensor MQ-2 mendeteksi konsentrasi asap sebesar <strong>${currentSensorState.mq2_ppm} PPM</strong> (Batas aman < 300 PPM). Tidak ada indikasi kebakaran atau kebocoran gas LPG.`;
      }
    } else if (q.includes('tips') || q.includes('hemat') || q.includes('jaga') || q.includes('k3')) {
      answer = "💡 <strong>Tips Keselamatan & K3 Laboratorium:</strong><br>1. Matikan solder dan alat pemanas listrik setelah selesai digunakan.<br>2. Pastikan ventilasi udara terbuka saat melakukan praktikum pengelasan atau perakitan.<br>3. Hubungi teknisi bengkel jika alarm sensor gas menyala.";
    } else {
      answer = `Terima kasih pertanyaannya! Berdasarkan pembacaan sensor node <code>${currentSensorState.nodeId}</code> secara langsung: Suhu: <strong>${currentSensorState.temp.toFixed(1)}°C</strong>, Kelembapan: <strong>${currentSensorState.hum.toFixed(1)}%</strong>, MQ-7 (CO): <strong>${currentSensorState.mq7_ppm} PPM</strong>, MQ-2 (Asap): <strong>${currentSensorState.mq2_ppm} PPM</strong>. Status: <strong>${currentSensorState.status}</strong>.`;
    }

    appendBotMessage(answer);
    chatHistory.push({ role: 'user', content: query });
    chatHistory.push({ role: 'model', content: answer });
  }, 400);
}

// --- 7. RESIZE LISTENER FOR TELEMETRY CANVAS ---
window.addEventListener('resize', () => {
  renderTelemetryCanvas();
});

// --- 8. INITIALIZATION ON PAGE LOAD ---
document.addEventListener("DOMContentLoaded", () => {
  // Inisialisasi Carousel
  restartSlideTimer();

  // Initial UI Render & Telemetry Canvas Draw
  applyDisplay(currentSensorState);
  renderTelemetryCanvas();

  // Polling data telemetri pertama dan berulang
  fetchLatestTelemetry();
  setInterval(fetchLatestTelemetry, (typeof CONFIG !== 'undefined' && CONFIG.POLL_INTERVAL) ? CONFIG.POLL_INTERVAL : 2500);

  console.log("🏭 Smart Environmental Sensing System (ESS) POLTEKOM initialized successfully!");
});

