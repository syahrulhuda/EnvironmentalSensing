/**
 * ==============================================================================
 * ESS Frontend Component: Telemetry Service & Display Updater
 * Mengelola state sensor, polling buffer Firebase RTDB, dan pembaruan UI kartu K3
 * ==============================================================================
 */

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

  // Kirim data pembacaan ke grafik sparkline canvas
  if (typeof pushTelemetryToSparklines === 'function') {
    pushTelemetryToSparklines(tempVal, mq7Val, mq2Val);
  }

  // Update Header K3 Status Indicator
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
}

function updateSystemStatus(isOnline) {
  const statusPill = document.getElementById('systemStatusPill');
  const statusText = document.getElementById('systemStatusText');
  const statusDot = statusPill ? statusPill.querySelector('span:first-child') : null;

  const scrolledPill = document.getElementById('scrolledStatusPill');
  const scrolledText = document.getElementById('scrolledStatusText');
  const scrolledDot = document.getElementById('scrolledStatusDot');

  if (isOnline) {
    if (statusText) statusText.innerText = "ONLINE";
    if (statusDot) statusDot.className = "w-2 h-2 rounded-full bg-emerald-400 animate-pulse";
    if (statusPill) {
      statusPill.classList.remove('status-offline');
      statusPill.classList.add('status-online');
      statusPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-xl border border-emerald-500/40 bg-emerald-500/15 text-emerald-400 text-xs font-mono font-semibold status-online transition-all";
    }

    if (scrolledText) scrolledText.innerText = "ONLINE";
    if (scrolledDot) scrolledDot.className = "w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse";
    if (scrolledPill) scrolledPill.className = "flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 text-[10px] font-mono font-semibold";
  } else {
    if (statusText) statusText.innerText = "OFFLINE";
    if (statusDot) statusDot.className = "w-2 h-2 rounded-full bg-rose-400";
    if (statusPill) {
      statusPill.classList.remove('status-online');
      statusPill.classList.add('status-offline');
      statusPill.className = "flex items-center gap-2 px-3 py-1.5 rounded-xl border border-rose-500/35 bg-rose-500/15 text-rose-400 text-xs font-mono font-semibold status-offline transition-all";
    }

    if (scrolledText) scrolledText.innerText = "OFFLINE";
    if (scrolledDot) scrolledDot.className = "w-1.5 h-1.5 rounded-full bg-rose-400";
    if (scrolledPill) scrolledPill.className = "flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-rose-500/15 border border-rose-500/30 text-rose-400 text-[10px] font-mono font-semibold";
  }
}

async function fetchLatestTelemetry() {
  if (typeof CONFIG === 'undefined' || !CONFIG.FIREBASE_DATABASE_URL) return;

  try {
    const res = await fetch(CONFIG.FIREBASE_DATABASE_URL);
    if (!res.ok) {
      updateSystemStatus(false);
      return;
    }

    const data = await res.json();
    if (!data) {
      updateSystemStatus(false);
      return;
    }

    const keys = Object.keys(data);
    if (keys.length === 0) {
      updateSystemStatus(false);
      return;
    }

    const targetNode = (typeof CONFIG !== 'undefined' ? CONFIG.DEFAULT_NODE_ID : "NODE-MRS01") || "NODE-MRS01";
    let record = null;

    // Cari record terbaru milik targetNode
    for (let i = keys.length - 1; i >= 0; i--) {
      const item = data[keys[i]];
      if (item && typeof item === 'object') {
        const itemNode = item.node_id || item.device_id;
        if (!itemNode || itemNode === targetNode) {
          record = item;
          break;
        }
      }
    }

    if (!record) {
      record = data[keys[keys.length - 1]];
    }
    if (!record) {
      updateSystemStatus(false);
      return;
    }

    // Update state sensor
    currentSensorState.temp = parseFloat(record.temp || record.temperature || 25.0);
    currentSensorState.hum = parseFloat(record.hum || record.humidity || 50.0);
    currentSensorState.mq7_ppm = parseInt(record.mq7_ppm || record.mq7 || 0, 10);
    currentSensorState.mq2_ppm = parseInt(record.mq2_ppm || record.mq2 || 0, 10);
    currentSensorState.nodeId = record.node_id || record.device_id || targetNode;
    currentSensorState.status = record.status || "NORMAL";
    currentSensorState.lastUpdated = new Date();

    // Heartbeat Watchdog: Validasi apakah timestamp record masih aktif (fresh)
    let recordTimeMs = null;
    if (typeof record.created_at === 'number') {
      recordTimeMs = record.created_at;
    } else if (typeof record.created_at === 'string') {
      const parsed = Date.parse(record.created_at);
      if (!isNaN(parsed)) {
        recordTimeMs = parsed;
      } else {
        const num = Number(record.created_at);
        if (!isNaN(num)) recordTimeMs = num;
      }
    } else if (record.timestamp) {
      const parsed = Date.parse(record.timestamp);
      if (!isNaN(parsed)) recordTimeMs = parsed;
    }

    // ESP32 mengirim data tiap 3 detik. Toleransi heartbeat: 15 detik (5 siklus)
    const HEARTBEAT_TIMEOUT_MS = 15000;
    const nowMs = Date.now();
    const isOnline = (recordTimeMs !== null) && (Math.abs(nowMs - recordTimeMs) <= HEARTBEAT_TIMEOUT_MS);

    updateSystemStatus(isOnline);

    // Terapkan ke tampilan UI
    applyDisplay(currentSensorState);

  } catch (err) {
    console.warn("[Firebase RTDB] Fetch stream error:", err);
    updateSystemStatus(false);
  }
}

// Ekspor ke window global
window.currentSensorState = currentSensorState;
window.applyDisplay = applyDisplay;
window.fetchLatestTelemetry = fetchLatestTelemetry;
