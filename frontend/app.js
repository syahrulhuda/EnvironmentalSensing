/**
 * ==============================================================================
 * AeroSense IoT - Core Application Logic
 * Environmental & Gas Safety Monitoring System
 * Target: ESP32-C3 Super Mini + Firebase RTDB + AI Assistant
 * ==============================================================================
 */

// --- GLOBAL STATE ---
let state = {
  temp: 26.4,
  humidity: 58,
  mq2: 124,
  mq7: 18,
  isDangerSimulated: false,
  audioAlarmEnabled: true,
  isFirebaseLive: false,
  rssi: -58,
  uptimeSeconds: 13338,
  filter: 'live',
  thresholds: {
    tempMax: (typeof CONFIG !== 'undefined' && CONFIG.THRESHOLDS) ? CONFIG.THRESHOLDS.TEMP_MAX : 35.0,
    mq2Max: (typeof CONFIG !== 'undefined' && CONFIG.THRESHOLDS) ? CONFIG.THRESHOLDS.MQ2_MAX : 300,
    mq7Max: (typeof CONFIG !== 'undefined' && CONFIG.THRESHOLDS) ? CONFIG.THRESHOLDS.MQ7_MAX : 50
  },
  history: []
};

// --- WEB AUDIO SYNTHESIZED SIREN ---
let audioCtx = null;
let alarmOscillator = null;
let isSirenRinging = false;

function initAudio() {
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (AudioContextClass) {
      audioCtx = new AudioContextClass();
    }
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
}

function startSirenSound() {
  if (!state.audioAlarmEnabled) return;
  initAudio();
  if (!audioCtx || isSirenRinging) return;

  try {
    isSirenRinging = true;
    alarmOscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();
    alarmOscillator.type = 'sawtooth';
    alarmOscillator.frequency.setValueAtTime(800, audioCtx.currentTime);
    alarmOscillator.frequency.exponentialRampToValueAtTime(1400, audioCtx.currentTime + 0.35);
    gainNode.gain.setValueAtTime(0.06, audioCtx.currentTime);
    alarmOscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    alarmOscillator.start();

    let freqToggle = false;
    alarmOscillator._interval = setInterval(() => {
      if (!alarmOscillator) return;
      freqToggle = !freqToggle;
      alarmOscillator.frequency.setValueAtTime(freqToggle ? 1300 : 750, audioCtx.currentTime);
    }, 400);
  } catch (e) {
    console.warn('Audio belum diizinkan oleh gesture browser:', e);
  }
}

function stopSirenSound() {
  isSirenRinging = false;
  if (alarmOscillator) {
    clearInterval(alarmOscillator._interval);
    try { alarmOscillator.stop(); } catch(e){}
    alarmOscillator.disconnect();
    alarmOscillator = null;
  }
}

function toggleAudioAlarm() {
  initAudio();
  state.audioAlarmEnabled = !state.audioAlarmEnabled;
  const btn = document.getElementById('audioToggleBtn');
  const icon = document.getElementById('audioIcon');
  if (!btn || !icon) return;

  if (state.audioAlarmEnabled) {
    btn.classList.remove('text-red-400', 'border-red-500/30');
    btn.classList.add('text-slate-300');
    icon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />`;
  } else {
    stopSirenSound();
    btn.classList.add('text-red-400', 'border-red-500/30');
    icon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15zM17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2" />`;
  }
}

// --- DANGER SIMULATOR TOGGLE ---
function toggleDangerSimulation() {
  initAudio();
  state.isDangerSimulated = !state.isDangerSimulated;
  const btn = document.getElementById('toggleDangerBtn');
  const btnText = document.getElementById('dangerBtnText');

  if (state.isDangerSimulated) {
    if (btn) {
      btn.className = "group relative px-3 py-1.5 rounded-lg bg-red-600 text-white font-bold text-xs flex items-center gap-1.5 transition-all shadow-lg shadow-red-500/50 animate-pulse";
    }
    if (btnText) btnText.innerText = "Stop Danger Sim";
    appendAIMessage("🚨 <strong>Mode Simulasi Bahaya Diaktifkan:</strong> Nilai Suhu (41.8°C), MQ-2 (540 PPM), dan MQ-7 (92 PPM) dinaikkan melampaui batas batas aman! Aktuator visual LED merah & alarm aktif!");
  } else {
    if (btn) {
      btn.className = "group relative px-3 py-1.5 rounded-lg bg-red-500/10 hover:bg-red-500/20 border border-red-500/30 text-red-300 hover:text-red-200 text-xs font-medium flex items-center gap-1.5 transition-all shadow-sm";
    }
    if (btnText) btnText.innerText = "Simulate Danger";
    stopSirenSound();
    appendAIMessage("✅ <strong>Mode Simulasi Dimatikan:</strong> Sistem kembali ke pemantauan normal.");
  }
  updateTelemetry();
}

// --- HISTORICAL DATA INITIALIZER ---
function initializeHistoricalData() {
  const now = Date.now();
  state.history = [];
  for (let i = 24; i >= 0; i--) {
    const time = new Date(now - i * 3000);
    state.history.push({
      time: time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
      temp: parseFloat((25 + Math.sin(i * 0.4) * 1.5 + (Math.random() * 0.6)).toFixed(1)),
      humidity: Math.round(56 + Math.cos(i * 0.3) * 4),
      mq2: Math.round(110 + Math.random() * 25),
      mq7: Math.round(15 + Math.random() * 8)
    });
  }
}

// --- TELEMETRY ENGINE & FIREBASE SYNC ---
async function fetchFirebaseTelemetry() {
  if (typeof CONFIG === 'undefined' || !CONFIG.FIREBASE_DATABASE_URL) return false;

  let url = CONFIG.FIREBASE_DATABASE_URL.replace(/\/+$/, "");
  if (!url.endsWith('.json')) {
    url += "/sensor_data.json";
  }
  if (CONFIG.FIREBASE_AUTH_TOKEN) {
    url += "?auth=" + encodeURIComponent(CONFIG.FIREBASE_AUTH_TOKEN);
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2500);
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);

    if (res.ok) {
      const data = await res.json();
      if (data && typeof data === 'object') {
        // Pemetaan field dari payload ESP32 sketch.ino
        if (data.temperature !== undefined) state.temp = parseFloat(data.temperature);
        if (data.humidity !== undefined) state.humidity = parseFloat(data.humidity);
        if (data.mq2_ppm !== undefined) state.mq2 = Math.round(data.mq2_ppm);
        if (data.mq7_ppm !== undefined) state.mq7 = Math.round(data.mq7_ppm);
        return true;
      }
    }
  } catch (err) {
    // Mode offline / Firebase belum aktif
  }
  return false;
}

async function updateTelemetry() {
  state.uptimeSeconds += 2;

  // Uptime formatting
  const h = String(Math.floor(state.uptimeSeconds / 3600)).padStart(2, '0');
  const m = String(Math.floor((state.uptimeSeconds % 3600) / 60)).padStart(2, '0');
  const s = String(state.uptimeSeconds % 60).padStart(2, '0');
  const elUptime = document.getElementById('diagUptime');
  if (elUptime) elUptime.innerText = `${h}h : ${m}m : ${s}s`;

  // Status Connection Pill
  const connPill = document.getElementById('connectionPill');
  const connText = document.getElementById('connectionStatusText');
  const connPing = document.getElementById('connectionPing');

  if (state.isDangerSimulated) {
    // Override dengan nilai simulasi darurat
    state.temp = 41.8;
    state.humidity = 35;
    state.mq2 = 540;
    state.mq7 = 92;
    if (connText) connText.innerText = "Danger Simulation";
  } else {
    // Coba baca dari Firebase terlebih dahulu
    const hasLiveFirebase = await fetchFirebaseTelemetry();
    state.isFirebaseLive = hasLiveFirebase;

    if (hasLiveFirebase) {
      if (connPill) connPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-lg bg-emerald-950/40 border border-emerald-500/30 text-emerald-400 text-xs font-medium font-mono transition-all";
      if (connText) connText.innerText = "Firebase RTDB Live";
      if (connPing) connPing.className = "animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75";
      const diagSync = document.getElementById('diagLastSync');
      if (diagSync) diagSync.innerText = "Synced (Live)";
    } else {
      // Fallback ke Realistic Simulator
      state.temp = +(state.temp + (Math.random() * 0.4 - 0.2)).toFixed(1);
      if (state.temp < 22) state.temp = 23;
      if (state.temp > 31) state.temp = 30;

      state.humidity = Math.round(state.humidity + (Math.random() * 2 - 1));
      if (state.humidity < 40) state.humidity = 42;
      if (state.humidity > 70) state.humidity = 68;

      state.mq2 = Math.round(state.mq2 + (Math.random() * 8 - 4));
      if (state.mq2 < 90) state.mq2 = 95;
      if (state.mq2 > 230) state.mq2 = 210;

      state.mq7 = Math.round(state.mq7 + (Math.random() * 4 - 2));
      if (state.mq7 < 10) state.mq7 = 12;
      if (state.mq7 > 35) state.mq7 = 32;

      if (connPill) connPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-lg bg-amber-950/40 border border-amber-500/30 text-amber-400 text-xs font-medium font-mono transition-all";
      if (connText) connText.innerText = "Live Simulator";
      if (connPing) connPing.className = "animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75";
      const diagSync = document.getElementById('diagLastSync');
      if (diagSync) diagSync.innerText = "Simulated";
    }
  }

  // Safety threshold check
  const isDanger = (
    state.temp >= state.thresholds.tempMax ||
    state.mq2 >= state.thresholds.mq2Max ||
    state.mq7 >= state.thresholds.mq7Max
  );

  // Render Card UI
  renderCardsUI(isDanger);

  // Push to history
  const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  state.history.push({
    time: timeStr,
    temp: state.temp,
    humidity: state.humidity,
    mq2: state.mq2,
    mq7: state.mq7
  });
  if (state.history.length > 25) state.history.shift();

  // Redraw Canvas Chart
  drawChart();
}

// --- RENDER TELEMETRY CARDS & EMERGENCY BANNER ---
function renderCardsUI(isDanger) {
  // DHT22 (Suhu & Kelembaban)
  const elValTemp = document.getElementById('valTemp');
  const elValHum = document.getElementById('valHum');
  const badgeDHT = document.getElementById('badgeDHT');
  if (elValTemp) elValTemp.innerText = state.temp.toFixed(1);
  if (elValHum) elValHum.innerText = state.humidity;
  if (badgeDHT) {
    if (state.temp >= state.thresholds.tempMax) {
      badgeDHT.className = "px-2 py-0.5 rounded-md text-[11px] font-medium bg-red-500/20 text-red-400 border border-red-500/30 animate-pulse";
      badgeDHT.innerText = "Overheat!";
    } else {
      badgeDHT.className = "px-2 py-0.5 rounded-md text-[11px] font-medium bg-emerald-500/15 text-emerald-400 border border-emerald-500/20";
      badgeDHT.innerText = "Optimal";
    }
  }

  // MQ-2 (LPG & Asap)
  const elValMQ2 = document.getElementById('valMQ2');
  const barMQ2 = document.getElementById('barMQ2');
  const badgeMQ2 = document.getElementById('badgeMQ2');
  if (elValMQ2) elValMQ2.innerText = state.mq2;
  const mq2Percent = Math.min(100, Math.round((state.mq2 / 600) * 100));
  if (barMQ2) barMQ2.style.width = mq2Percent + '%';
  if (badgeMQ2) {
    if (state.mq2 >= state.thresholds.mq2Max) {
      badgeMQ2.className = "px-2 py-0.5 rounded-md text-[11px] font-medium bg-red-500/20 text-red-400 border border-red-500/30 animate-pulse";
      badgeMQ2.innerText = "LEAK DETECTED!";
    } else {
      badgeMQ2.className = "px-2 py-0.5 rounded-md text-[11px] font-medium bg-emerald-500/15 text-emerald-400 border border-emerald-500/20";
      badgeMQ2.innerText = "Clean Air";
    }
  }

  // MQ-7 (Karbon Monoksida / CO)
  const elValMQ7 = document.getElementById('valMQ7');
  const barMQ7 = document.getElementById('barMQ7');
  const badgeMQ7 = document.getElementById('badgeMQ7');
  if (elValMQ7) elValMQ7.innerText = state.mq7;
  const mq7Percent = Math.min(100, Math.round((state.mq7 / 120) * 100));
  if (barMQ7) barMQ7.style.width = mq7Percent + '%';
  if (badgeMQ7) {
    if (state.mq7 >= state.thresholds.mq7Max) {
      badgeMQ7.className = "px-2 py-0.5 rounded-md text-[11px] font-medium bg-red-500/20 text-red-400 border border-red-500/30 animate-pulse";
      badgeMQ7.innerText = "TOXIC HAZARD!";
    } else {
      badgeMQ7.className = "px-2 py-0.5 rounded-md text-[11px] font-medium bg-emerald-500/15 text-emerald-400 border border-emerald-500/20";
      badgeMQ7.innerText = "Harmless";
    }
  }

  // EMERGENCY BANNER & HARDWARE ACTUATOR (GPIO 5 LED)
  const banner = document.getElementById('alertBanner');
  const bannerTitle = document.getElementById('bannerTitle');
  const bannerDesc = document.getElementById('bannerDescription');
  const bannerBadge = document.getElementById('bannerModeBadge');
  const bannerIconWrapper = document.getElementById('bannerIconWrapper');
  const bannerIcon = document.getElementById('bannerIcon');
  const actuatorVal = document.getElementById('actuatorVal');
  const ledLight = document.getElementById('hardwareLedLight');

  if (isDanger) {
    if (banner) banner.className = "relative overflow-hidden rounded-2xl p-4 sm:p-5 transition-all duration-500 border bg-red-950/40 border-red-500/60 text-red-200 neon-border-danger";
    if (bannerTitle) {
      bannerTitle.className = "font-extrabold text-sm sm:text-base tracking-wide uppercase text-red-400 flex items-center gap-2";
      bannerTitle.innerHTML = `⚠️ DANGER: SAFETY THRESHOLD BREACHED!`;
    }
    if (bannerBadge) {
      bannerBadge.className = "text-[10px] font-mono px-2 py-0.5 rounded bg-red-500/30 text-red-200 border border-red-500/50 animate-pulse";
      bannerBadge.innerText = "CRITICAL EVACUATION PROTOCOL";
    }
    if (bannerDesc) {
      bannerDesc.innerText = `Kondisi berbahaya terdeteksi: Suhu (≥${state.thresholds.tempMax}°C), Gas MQ-2 (≥${state.thresholds.mq2Max} PPM), atau Gas CO (≥${state.thresholds.mq7Max} PPM) melampaui batas. Indikator fisik LED Merah GPIO 5 Aktif!`;
    }
    if (bannerIconWrapper) {
      bannerIconWrapper.className = "flex-shrink-0 w-11 h-11 rounded-xl bg-red-500/30 border border-red-500 flex items-center justify-center text-red-400 animate-bounce";
    }
    if (bannerIcon) {
      bannerIcon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />`;
    }

    if (actuatorVal) actuatorVal.innerHTML = `<span class="text-red-400 font-extrabold animate-pulse">ACTIVE HIGH (BLAZING RED)</span>`;
    if (ledLight) ledLight.className = "w-4 h-4 rounded-full bg-red-500 border-2 border-white shadow-[0_0_18px_#ef4444] animate-ping-siren";

    startSirenSound();
  } else {
    if (banner) banner.className = "relative overflow-hidden rounded-2xl p-4 sm:p-5 transition-all duration-500 border bg-emerald-950/20 border-emerald-500/30 text-emerald-300";
    if (bannerTitle) {
      bannerTitle.className = "font-bold text-sm sm:text-base tracking-wide uppercase text-emerald-400";
      bannerTitle.innerText = "Environment Normal";
    }
    if (bannerBadge) {
      bannerBadge.className = "text-[10px] font-mono px-2 py-0.5 rounded bg-white/10 text-white/80";
      bannerBadge.innerText = "ALL SENSORS COMPLIANT";
    }
    if (bannerDesc) {
      bannerDesc.innerText = "Parameter udara dan suhu terpantau aman dalam batas baku mutu K3 & OSHA. Tidak ada kebocoran gas.";
    }
    if (bannerIconWrapper) {
      bannerIconWrapper.className = "flex-shrink-0 w-11 h-11 rounded-xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400";
    }
    if (bannerIcon) {
      bannerIcon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />`;
    }

    if (actuatorVal) actuatorVal.innerHTML = `<span class="text-slate-400 font-medium">STANDBY (OFF)</span>`;
    if (ledLight) ledLight.className = "w-4 h-4 rounded-full bg-slate-600 border border-slate-400 transition-all duration-300";

    stopSirenSound();
  }
}

// --- CANVAS GRAPH DRAWING LOGIC ---
function getCoords(index, val, maxScale, width, height, paddingLeft, paddingBottom) {
  const graphW = width - paddingLeft - 10;
  const graphH = height - paddingBottom - 10;
  const x = paddingLeft + (index / (state.history.length - 1)) * graphW;
  const y = 10 + graphH * (1 - (val / maxScale));
  return { x, y };
}

function drawChart() {
  const canvas = document.getElementById('telemetryCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;

  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);

  const width = rect.width;
  const height = rect.height;
  const paddingLeft = 35;
  const paddingBottom = 25;

  ctx.clearRect(0, 0, width, height);
  if (state.history.length < 2) return;

  const maxScale = 300;

  // Grid background lines
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
  ctx.lineWidth = 1;
  ctx.fillStyle = '#64748b';
  ctx.font = '10px "JetBrains Mono", monospace';

  const steps = 4;
  for (let i = 0; i <= steps; i++) {
    const yVal = Math.round((maxScale / steps) * i);
    const y = 10 + (height - paddingBottom - 10) * (1 - (i / steps));
    ctx.beginPath();
    ctx.moveTo(paddingLeft, y);
    ctx.lineTo(width - 10, y);
    ctx.stroke();
    ctx.fillText(yVal, 5, y + 3);
  }

  // Red Hazard Reference Line (Ambang MQ-2 300 PPM)
  const dangerY = 10 + (height - paddingBottom - 10) * (1 - (state.thresholds.mq2Max / maxScale));
  ctx.strokeStyle = 'rgba(239, 68, 68, 0.4)';
  ctx.setLineDash([4, 4]);
  ctx.beginPath();
  ctx.moveTo(paddingLeft, dangerY);
  ctx.lineTo(width - 10, dangerY);
  ctx.stroke();
  ctx.setLineDash([]);

  // Time timestamps along bottom
  ctx.fillStyle = '#64748b';
  const labelInterval = Math.max(1, Math.floor(state.history.length / 4));
  for (let i = 0; i < state.history.length; i += labelInterval) {
    const { x } = getCoords(i, 0, maxScale, width, height, paddingLeft, paddingBottom);
    ctx.fillText(state.history[i].time, x - 15, height - 8);
  }

  // Render MQ-2 line (Amber)
  renderSeries(ctx, state.history, d => d.mq2, maxScale, '#f59e0b', 'rgba(245, 158, 11, 0.08)');

  // Render Temperature line (Cyan)
  renderSeries(ctx, state.history, d => d.temp * 4, maxScale, '#38bdf8', 'rgba(56, 189, 248, 0.08)');

  // Render MQ-7 line (Purple)
  renderSeries(ctx, state.history, d => d.mq7 * 2.5, maxScale, '#a855f7', 'rgba(168, 85, 247, 0.08)');
}

function renderSeries(ctx, data, valueAccessor, maxScale, strokeColor, fillColor) {
  const paddingLeft = 35;
  const paddingBottom = 25;
  const width = ctx.canvas.width / (window.devicePixelRatio || 1);
  const height = ctx.canvas.height / (window.devicePixelRatio || 1);
  const graphW = width - paddingLeft - 10;
  const graphH = height - paddingBottom - 10;

  ctx.beginPath();
  let firstCoord;
  data.forEach((d, idx) => {
    const val = Math.min(maxScale, valueAccessor(d));
    const x = paddingLeft + (idx / (data.length - 1)) * graphW;
    const y = 10 + graphH * (1 - (val / maxScale));
    if (idx === 0) {
      firstCoord = { x, y };
      ctx.moveTo(x, y);
    } else {
      ctx.lineTo(x, y);
    }
  });

  ctx.strokeStyle = strokeColor;
  ctx.lineWidth = 2;
  ctx.stroke();

  // Filled gradient underneath
  ctx.lineTo(paddingLeft + graphW, 10 + graphH);
  ctx.lineTo(firstCoord.x, 10 + graphH);
  ctx.closePath();
  ctx.fillStyle = fillColor;
  ctx.fill();
}

window.addEventListener('resize', drawChart);

function setChartFilter(mode) {
  state.filter = mode;
  ['filterLive', 'filter1h', 'filter24h'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.className = "px-2.5 py-1 rounded text-slate-400 hover:text-white transition";
  });
  const activeEl = document.getElementById(mode === 'live' ? 'filterLive' : (mode === '1h' ? 'filter1h' : 'filter24h'));
  if (activeEl) activeEl.className = "px-2.5 py-1 rounded bg-cyan-500/20 text-cyan-300 font-semibold transition";
}

// --- EXPORT CSV FUNCTIONALITY ---
function exportCSVData() {
  let csv = "Timestamp,Temperature_C,Humidity_Percent,MQ2_Gas_PPM,MQ7_CO_PPM\n";
  state.history.forEach(row => {
    csv += `${row.time},${row.temp},${row.humidity},${row.mq2},${row.mq7}\n`;
  });
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.setAttribute("href", url);
  link.setAttribute("download", `AeroSense_Telemetry_${new Date().toISOString().slice(0,10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// --- AI ASSISTANT CHATBOT LOGIC ---
function appendUserMessage(text) {
  const feed = document.getElementById('aiChatFeed');
  if (!feed) return;
  const msg = document.createElement('div');
  msg.className = "flex gap-2 justify-end animate-fadeIn";
  msg.innerHTML = `
    <div class="bg-cyan-500/20 border border-cyan-400/30 text-cyan-100 rounded-2xl rounded-tr-none p-3 max-w-[85%] leading-relaxed">
      ${text}
    </div>
  `;
  feed.appendChild(msg);
  feed.scrollTop = feed.scrollHeight;
}

function appendAIMessage(text) {
  const feed = document.getElementById('aiChatFeed');
  if (!feed) return;
  const msg = document.createElement('div');
  msg.className = "flex gap-2.5 items-start animate-fadeIn";
  msg.innerHTML = `
    <div class="w-6 h-6 rounded-md bg-purple-600/30 border border-purple-400/40 flex-shrink-0 flex items-center justify-center text-[10px] text-purple-300 font-bold font-mono">AI</div>
    <div class="bg-slate-800/80 rounded-2xl rounded-tl-none p-3 border border-white/5 text-slate-200 max-w-[90%] leading-relaxed">
      ${text}
    </div>
  `;
  feed.appendChild(msg);
  feed.scrollTop = feed.scrollHeight;
}

function handleChatSubmit(e) {
  e.preventDefault();
  const input = document.getElementById('chatInput');
  if (!input) return;
  const prompt = input.value.trim();
  if (!prompt) return;
  input.value = '';
  appendUserMessage(prompt);
  processAIQuery(prompt);
}

function sendQuickPrompt(promptText) {
  appendUserMessage(promptText);
  processAIQuery(promptText);
}

function processAIQuery(query) {
  const q = query.toLowerCase();
  setTimeout(() => {
    let reply = "";
    if (q.includes('suhu') || q.includes('temp') || q.includes('kelembapan') || q.includes('dht22')) {
      reply = `🌡️ <strong>Analisis DHT22:</strong> Suhu saat ini <strong>${state.temp}°C</strong> dan Kelembapan <strong>${state.humidity}%</strong>. Ambang batas panas yang disetel adalah ${state.thresholds.tempMax}°C. ${state.temp >= state.thresholds.tempMax ? '⚠️ <span class="text-red-400 font-bold">PERINGATAN:</span> Suhu melampaui batas batas! Harap periksa sirkulasi ruangan.' : 'Kondisi mikroklimat ruangan tergolong ideal dan normal.'}`;
    } else if (q.includes('mq-2') || q.includes('lpg') || q.includes('asap') || q.includes('gas')) {
      reply = `🔥 <strong>Analisis Sensor MQ-2:</strong> Konsentrasi gas & asap terukur <strong>${state.mq2} PPM</strong> (Ambang batas aman &lt; ${state.thresholds.mq2Max} PPM). ${state.mq2 >= state.thresholds.mq2Max ? '🚨 <span class="text-red-400 font-bold">BAHAYA:</span> Kebocoran gas mudah terbakar atau asap terdeteksi! Segera matikan api dan evakuasi area!' : 'Udara bersih dari akumulasi gas metana, LPG, maupun partikel asap tebal.'}`;
    } else if (q.includes('co') || q.includes('karbon') || q.includes('mq-7') || q.includes('beracun')) {
      reply = `⚠️ <strong>Analisis Toksisitas CO (MQ-7):</strong> Konsentrasi Karbon Monoksida terdeteksi <strong>${state.mq7} PPM</strong> (Batas bahaya: ${state.thresholds.mq7Max} PPM). ${state.mq7 >= state.thresholds.mq7Max ? '☠️ <span class="text-red-400 font-bold">DARURAT KRITIS:</span> Tingkat CO berbahaya bagi pernapasan. Segera nyalakan exhaust fan darurat!' : 'Kandungan gas CO dalam batas alami aman.'}`;
    } else if (q.includes('laporan') || q.includes('audit') || q.includes('total')) {
      const isSafe = state.temp < state.thresholds.tempMax && state.mq2 < state.thresholds.mq2Max && state.mq7 < state.thresholds.mq7Max;
      reply = `🛡️ <strong>Laporan Audit Keselamatan AeroSense:</strong><br>
      • <strong>Status Sistem:</strong> ${isSafe ? '<span class="text-emerald-400 font-bold">NORMAL & AMAN</span>' : '<span class="text-red-400 font-bold animate-pulse">DARURAT (ALERT)</span>'}<br>
      • <strong>Hardware Node:</strong> ESP32-C3 Super Mini (${state.isFirebaseLive ? 'Firebase Live' : 'Simulator Mode'})<br>
      • <strong>Indikator LED GPIO 5:</strong> ${isSafe ? 'OFF (Normal Standby)' : 'ON (Blazing Red - Danger Mode)'}<br>
      • <strong>Suhu / Kelembaban:</strong> ${state.temp}°C / ${state.humidity}%<br>
      • <strong>Kadar MQ-2 / MQ-7:</strong> ${state.mq2} PPM / ${state.mq7} PPM`;
    } else if (q.includes('evakuasi') || q.includes('sop') || q.includes('prosedur')) {
      reply = `💡 <strong>SOP Evakuasi Darurat AeroSense:</strong><br>
      1. <strong>Tutup Hidung & Mulut:</strong> Gunakan kain basah bila terdeteksi asap atau gas CO.<br>
      2. <strong>Jangan Nyalakan Saklar Listrik:</strong> Bila gas MQ-2 tinggi, percikan saklar dapat memicu ledakan.<br>
      3. <strong>Buka Jalur Ventilasi:</strong> Segera buka pintu keluar darurat dan jendela utama.<br>
      4. <strong>Kumpul di Titik Aman:</strong> Menjauh minimal 50 meter dari zona perimeter sensor.`;
    } else {
      reply = `Telemetri real-time saat ini: Suhu: <strong>${state.temp}°C</strong>, MQ-2: <strong>${state.mq2} PPM</strong>, MQ-7: <strong>${state.mq7} PPM</strong>. Semua sensor terpantau oleh ESP32-C3. Silakan pilih tombol pertanyaan cepat di atas atau tanyakan parameter keselamatan lainnya.`;
    }
    appendAIMessage(reply);
  }, 350);
}

// --- CONFIGURATION MODAL CONTROLS ---
function openConfigModal() {
  const modal = document.getElementById('settingsModal');
  if (!modal) return;
  modal.classList.remove('opacity-0', 'pointer-events-none');

  // Isi input form dengan konfigurasi aktif
  const inputUrl = document.getElementById('cfgDbUrl');
  const inputToken = document.getElementById('cfgDbToken');
  const inputTemp = document.getElementById('cfgTempMax');
  const inputMQ2 = document.getElementById('cfgMQ2Max');
  const inputMQ7 = document.getElementById('cfgMQ7Max');

  if (inputUrl && typeof CONFIG !== 'undefined') inputUrl.value = CONFIG.FIREBASE_DATABASE_URL || '';
  if (inputToken && typeof CONFIG !== 'undefined') inputToken.value = CONFIG.FIREBASE_AUTH_TOKEN || '';
  if (inputTemp) inputTemp.value = state.thresholds.tempMax;
  if (inputMQ2) inputMQ2.value = state.thresholds.mq2Max;
  if (inputMQ7) inputMQ7.value = state.thresholds.mq7Max;
}

function closeConfigModal() {
  const modal = document.getElementById('settingsModal');
  if (modal) modal.classList.add('opacity-0', 'pointer-events-none');
}

async function testFirebaseConnection() {
  const spinner = document.getElementById('testSpinner');
  const label = document.getElementById('testBtnLabel');
  const inputUrl = document.getElementById('cfgDbUrl');
  if (spinner) spinner.classList.remove('hidden');
  if (label) label.innerText = 'Connecting...';

  const testUrl = inputUrl ? inputUrl.value.trim() : (CONFIG.FIREBASE_DATABASE_URL || '');
  let success = false;

  if (testUrl) {
    try {
      let finalUrl = testUrl.replace(/\/+$/, "");
      if (!finalUrl.endsWith('.json')) finalUrl += "/sensor_data.json";
      const res = await fetch(finalUrl);
      if (res.ok) success = true;
    } catch(e) {
      success = false;
    }
  }

  setTimeout(() => {
    if (spinner) spinner.classList.add('hidden');
    if (label) {
      label.innerText = success ? 'Connected! (HTTP 200 OK)' : 'Offline / Check URL';
      setTimeout(() => { label.innerText = 'Test Connection'; }, 3000);
    }
  }, 800);
}

function saveConfiguration() {
  const inputUrl = document.getElementById('cfgDbUrl');
  const inputToken = document.getElementById('cfgDbToken');
  const inputTemp = document.getElementById('cfgTempMax');
  const inputMQ2 = document.getElementById('cfgMQ2Max');
  const inputMQ7 = document.getElementById('cfgMQ7Max');

  if (inputUrl && typeof CONFIG !== 'undefined') {
    CONFIG.FIREBASE_DATABASE_URL = inputUrl.value.trim();
    localStorage.setItem("aerosense_cfg_db_url", CONFIG.FIREBASE_DATABASE_URL);
  }
  if (inputToken && typeof CONFIG !== 'undefined') {
    CONFIG.FIREBASE_AUTH_TOKEN = inputToken.value.trim();
    localStorage.setItem("aerosense_cfg_db_token", CONFIG.FIREBASE_AUTH_TOKEN);
  }

  const tempMax = parseFloat(inputTemp ? inputTemp.value : 35);
  const mq2Max = parseFloat(inputMQ2 ? inputMQ2.value : 300);
  const mq7Max = parseFloat(inputMQ7 ? inputMQ7.value : 50);

  if (!isNaN(tempMax)) {
    state.thresholds.tempMax = tempMax;
    localStorage.setItem("aerosense_cfg_temp_max", tempMax);
  }
  if (!isNaN(mq2Max)) {
    state.thresholds.mq2Max = mq2Max;
    localStorage.setItem("aerosense_cfg_mq2_max", mq2Max);
  }
  if (!isNaN(mq7Max)) {
    state.thresholds.mq7Max = mq7Max;
    localStorage.setItem("aerosense_cfg_mq7_max", mq7Max);
  }

  closeConfigModal();
  appendAIMessage(`⚙️ <strong>Pengaturan Disimpan:</strong> Ambang batas diperbarui ke Suhu: ${state.thresholds.tempMax}°C, MQ-2: ${state.thresholds.mq2Max} PPM, MQ-7: ${state.thresholds.mq7Max} PPM.`);
  updateTelemetry();
}

// --- BOOTSTRAP ---
window.addEventListener('DOMContentLoaded', () => {
  initializeHistoricalData();
  drawChart();
  updateTelemetry();
  // Tick pembaruan setiap interval polling (default 2 detik)
  const interval = (typeof CONFIG !== 'undefined' && CONFIG.POLL_INTERVAL) ? CONFIG.POLL_INTERVAL : 2000;
  setInterval(updateTelemetry, interval);
});
