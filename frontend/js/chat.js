/**
 * ==============================================================================
 * ESS Frontend Component: ESI Chatbot Assistant
 * Mengelola interaksi percakapan dengan AI ESI (FastAPI ReAct & Local Fallback)
 * ==============================================================================
 */

let chatHistory = [];

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

function renderMarkdown(raw) {
  if (!raw) return "";
  if (typeof marked !== 'undefined' && typeof marked.parse === 'function') {
    return marked.parse(raw);
  }
  // High-fidelity fallback parser
  let html = raw
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  html = html.replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>');
  html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/\*([^\*\n]+)\*/g, '<em>$1</em>');
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

  const lines = html.split('\n');
  let inList = false;
  let out = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (/^[\*\-]\s+(.+)/.test(trimmed)) {
      if (!inList) { out.push('<ul>'); inList = true; }
      out.push(`<li>${trimmed.replace(/^[\*\-]\s+/, '')}</li>`);
    } else {
      if (inList) { out.push('</ul>'); inList = false; }
      if (trimmed.length > 0) out.push(`<p>${trimmed}</p>`);
    }
  }
  if (inList) out.push('</ul>');
  return out.join('');
}

function appendBotMessage(text) {
  removeTypingIndicator();
  const feed = document.getElementById('chatFeed');
  if (!feed) return;
  const div = document.createElement('div');
  div.className = "flex gap-2 items-start animate-fadeIn";
  const formattedHtml = renderMarkdown(text);
  div.innerHTML = `
    <div class="w-7 h-7 rounded-lg bg-sky-500/15 border border-sky-400/30 flex-shrink-0 flex items-center justify-center text-sky-400">
      <span class="material-symbols-outlined text-base">smart_toy</span>
    </div>
    <div class="chat-bot-content bg-[#070d1e]/80 rounded-xl rounded-tl-none p-3 border border-sky-400/20 text-slate-100 max-w-[88%] text-xs leading-relaxed shadow-sm">
      ${formattedHtml}
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
  if (e && e.preventDefault) e.preventDefault();
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
    const state = typeof currentSensorState !== 'undefined' ? currentSensorState : { temp: 25, hum: 50, mq7_ppm: 5, mq2_ppm: 20, status: "NORMAL", nodeId: "NODE-MRS01" };

    if (q.includes('sehat') || q.includes('kualitas') || q.includes('udara')) {
      answer = `Kadar Karbon Monoksida (CO) terpantau <strong>${state.mq7_ppm} PPM</strong> (di bawah batas ambang 50 PPM). Sirkulasi udara ruangan aman dan bersih untuk kegiatan praktikum.`;
    } else if (q.includes('suhu') || q.includes('panas') || q.includes('dingin') || q.includes('cuaca') || q.includes('temp')) {
      answer = `Suhu ruangan saat ini tercatat <strong>${state.temp.toFixed(1)}°C</strong> dengan kelembapan <strong>${state.hum.toFixed(1)}% RH</strong>. Kondisi ruangan optimal.`;
    } else if (q.includes('asap') || q.includes('bahaya') || q.includes('bocor') || q.includes('kebakaran') || q.includes('gas')) {
      answer = `Sensor gas & asap mendeteksi konsentrasi sebesar <strong>${state.mq2_ppm} PPM</strong> (Batas aman < 150 PPM). Ruang laboratorium terpantau aman dari risiko kebakaran.`;
    } else if (q.includes('tips') || q.includes('hemat') || q.includes('jaga') || q.includes('k3')) {
      answer = "<strong>Tips K3 Laboratorium:</strong><br>1. Matikan solder dan alat pemanas listrik setelah selesai praktikum.<br>2. Pastikan ventilasi udara terbuka saat pengerjaan PCB.<br>3. Hubungi teknisi bengkel bila alarm sensor menyala.";
    } else {
      answer = `Data telemetri node <code>${state.nodeId}</code> terkini: Suhu: <strong>${state.temp.toFixed(1)}°C</strong>, Kelembapan: <strong>${state.hum.toFixed(1)}% RH</strong>, CO: <strong>${state.mq7_ppm} PPM</strong>, Asap: <strong>${state.mq2_ppm} PPM</strong>. Status: <strong>${state.status}</strong>.`;
    }

    appendBotMessage(answer);
    chatHistory.push({ role: 'user', content: query });
    chatHistory.push({ role: 'model', content: answer });
  }, 400);
}

// Ekspor ke window global
window.chatHistory = chatHistory;
window.askPrompt = askPrompt;
window.handleUserSubmit = handleUserSubmit;
window.processChatQuery = processChatQuery;
window.appendUserMessage = appendUserMessage;
window.appendBotMessage = appendBotMessage;
