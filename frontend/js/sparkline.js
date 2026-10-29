/**
 * ==============================================================================
 * ESS Frontend Component: Sparkline Canvas Renderer
 * Menggambar grafik canvas sparkline real-time untuk kartu Suhu, Asap, dan CO
 * ==============================================================================
 */

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
  const lastPt = telemetryHistory[telemetryHistory.length - 1] || (typeof currentSensorState !== 'undefined' ? currentSensorState : { temp: 25, mq2: 20, mq7: 5 });
  
  // K3 Color determination for dots
  const tempDot = lastPt.temp > 35.0 ? '#ef4444' : (lastPt.temp > 30.0 ? '#f59e0b' : '#10b981');
  const smokeDot = lastPt.mq2 > 300 ? '#ef4444' : (lastPt.mq2 > 150 ? '#f59e0b' : '#10b981');
  const toxDot = lastPt.mq7 > 50 ? '#ef4444' : (lastPt.mq7 > 25 ? '#f59e0b' : '#10b981');

  renderSparkline('canvasTemp', pt => pt.temp, 50, tempDot);
  renderSparkline('canvasSmoke', pt => pt.mq2, 500, smokeDot);
  renderSparkline('canvasTox', pt => pt.mq7, 100, toxDot);
}

// Ekspor ke window global
window.pushTelemetryToSparklines = pushTelemetryToSparklines;
window.renderSparkline = renderSparkline;
window.renderAllSparklines = renderAllSparklines;
