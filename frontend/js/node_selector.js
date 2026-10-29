/**
 * ==============================================================================
 * ESS Frontend Component: Node Selector & Supabase Dropdown
 * Mengelola pemilihan node pemantauan dan integrasi daftar node Supabase
 * ==============================================================================
 */

let registeredDevicesCache = [];
let isNodeDropdownOpen = false;

function toggleNodeDropdown(e) {
  if (e) e.stopPropagation();
  const menu = document.getElementById('nodeDropdownMenu');
  const btn = document.getElementById('nodeDropdownBtn');
  const chevron = document.getElementById('nodeDropdownChevron');
  if (!menu) return;

  isNodeDropdownOpen = !isNodeDropdownOpen;
  if (isNodeDropdownOpen) {
    menu.classList.remove('hidden');
    if (btn) btn.setAttribute('aria-expanded', 'true');
    if (chevron) chevron.innerText = 'expand_less';
  } else {
    menu.classList.add('hidden');
    if (btn) btn.setAttribute('aria-expanded', 'false');
    if (chevron) chevron.innerText = 'expand_more';
  }
}

function closeNodeDropdown() {
  if (!isNodeDropdownOpen) return;
  const menu = document.getElementById('nodeDropdownMenu');
  const btn = document.getElementById('nodeDropdownBtn');
  const chevron = document.getElementById('nodeDropdownChevron');
  if (menu) menu.classList.add('hidden');
  if (btn) btn.setAttribute('aria-expanded', 'false');
  if (chevron) chevron.innerText = 'expand_more';
  isNodeDropdownOpen = false;
}

// Global click outside to dismiss custom dropdown
window.addEventListener('click', (e) => {
  const wrapper = document.getElementById('nodeDropdownWrapper');
  if (wrapper && !wrapper.contains(e.target)) {
    closeNodeDropdown();
  }
});

// Escape key to dismiss
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeNodeDropdown();
  }
});

function updateNodeLocationSubtitle(nodeId) {
  const subtitle = document.getElementById('nodeLocationSubtitle');
  if (!subtitle) return;

  const dev = registeredDevicesCache.find(d => d.id === nodeId);
  if (dev) {
    if (dev.id === 'NODE-MRS01') {
      subtitle.innerText = 'Bengkel Mekatronika POLTEKOM (Soldering Zone 1)';
    } else if (dev.ess_zones && dev.ess_zones.zone_name) {
      subtitle.innerText = `Bengkel Mekatronika POLTEKOM (${dev.ess_zones.zone_name})`;
    } else if (dev.device_name) {
      subtitle.innerText = `Bengkel Mekatronika POLTEKOM (${dev.device_name})`;
    } else {
      subtitle.innerText = `Bengkel Mekatronika POLTEKOM (${dev.id})`;
    }
  } else {
    if (nodeId === 'NODE-MRS01') {
      subtitle.innerText = 'Bengkel Mekatronika POLTEKOM (Soldering Zone 1)';
    } else {
      subtitle.innerText = `Bengkel Mekatronika POLTEKOM (${nodeId})`;
    }
  }
}

function renderNodeDropdownItems(selectedNode) {
  const list = document.getElementById('nodeDropdownList');
  const selectedText = document.getElementById('nodeDropdownSelectedText');
  const menuCurrentText = document.getElementById('nodeDropdownMenuCurrentText');

  if (selectedText) {
    selectedText.innerText = selectedNode || 'NODE-MRS01';
  }
  if (menuCurrentText) {
    menuCurrentText.innerText = selectedNode || 'NODE-MRS01';
  }
  if (!list) return;

  list.innerHTML = '';
  registeredDevicesCache.forEach(dev => {
    const isSelected = dev.id === selectedNode;
    let zoneDesc = 'Soldering Zone 1';
    if (dev.id === 'NODE-MRS01') {
      zoneDesc = 'Soldering Zone 1';
    } else if (dev.ess_zones && dev.ess_zones.zone_name) {
      zoneDesc = dev.ess_zones.zone_name;
    } else if (dev.device_name) {
      zoneDesc = dev.device_name;
    } else {
      zoneDesc = 'Environmental Sensor';
    }

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = `w-full text-left px-3.5 py-2.5 rounded-xl text-xs font-mono transition-all duration-150 flex items-center justify-between group cursor-pointer ${
      isSelected
        ? 'bg-sky-500/20 text-white font-bold border border-sky-400/35 shadow-sm'
        : 'hover:bg-white/5 text-slate-300 hover:text-white border border-transparent'
    }`;
    btn.onclick = (e) => {
      e.stopPropagation();
      selectNode(dev.id);
    };

    btn.innerHTML = `
      <div class="flex flex-col">
        <div class="flex items-center gap-2">
          <span class="w-2 h-2 rounded-full ${isSelected ? 'bg-sky-400 animate-pulse' : 'bg-slate-500'}"></span>
          <span class="font-bold tracking-wide ${isSelected ? 'text-white' : 'text-slate-200 group-hover:text-white'}">${dev.id}</span>
        </div>
        <span class="text-[10px] text-slate-400 font-sans ml-4 mt-0.5">${zoneDesc}</span>
      </div>
      ${isSelected ? '<span class="material-symbols-outlined text-sm text-sky-400">check</span>' : ''}
    `;
    list.appendChild(btn);
  });
}

function selectNode(nodeId) {
  if (!nodeId) return;
  if (typeof CONFIG !== 'undefined') {
    CONFIG.DEFAULT_NODE_ID = nodeId;
  }
  localStorage.setItem('ess_cfg_node_id', nodeId);
  if (typeof currentSensorState !== 'undefined') {
    currentSensorState.nodeId = nodeId;
  }
  console.log(`[ESS Node Switch] Monitoring aktif dialihkan ke node: ${nodeId}`);
  renderNodeDropdownItems(nodeId);
  updateNodeLocationSubtitle(nodeId);
  closeNodeDropdown();
  if (typeof fetchLatestTelemetry === 'function') {
    fetchLatestTelemetry();
  }
}

function populateNodeDropdown(deviceList, selectedNode) {
  registeredDevicesCache = deviceList || [];
  renderNodeDropdownItems(selectedNode);
  updateNodeLocationSubtitle(selectedNode);
}

async function fetchRegisteredNodes() {
  const savedNode = localStorage.getItem('ess_cfg_node_id') || (typeof CONFIG !== 'undefined' ? CONFIG.DEFAULT_NODE_ID : 'NODE-MRS01') || 'NODE-MRS01';

  try {
    // 1. Ambil daftar node resmi dari Supabase PostgreSQL via FastAPI Backend Gateway
    if (typeof CONFIG !== 'undefined' && CONFIG.BACKEND_API_URL) {
      const res = await fetch(`${CONFIG.BACKEND_API_URL}/api/devices`);
      if (res.ok) {
        const json = await res.json();
        if (json && Array.isArray(json.data) && json.data.length > 0) {
          populateNodeDropdown(json.data, savedNode);
          return;
        }
      }
    }
  } catch (err) {
    console.warn("[Node Selector] Backend gateway offline, fallback ke RTDB/cache:", err);
  }

  // 2. Fallback: Ekstrak node unik dari Firebase RTDB buffer
  try {
    if (typeof CONFIG !== 'undefined' && CONFIG.FIREBASE_DATABASE_URL) {
      const res = await fetch(CONFIG.FIREBASE_DATABASE_URL);
      if (res.ok) {
        const buffer = await res.json();
        if (buffer && typeof buffer === 'object') {
          const uniqueNodes = new Set();
          Object.values(buffer).forEach(item => {
            if (item && (item.node_id || item.device_id)) {
              uniqueNodes.add(item.node_id || item.device_id);
            }
          });
          if (uniqueNodes.size > 0) {
            const deviceList = Array.from(uniqueNodes).map(id => ({
              id: id,
              device_name: id === 'NODE-MRS01' ? 'Soldering Station Node 1' : 'Environmental Node',
              ess_zones: { zone_name: id === 'NODE-MRS01' ? 'Soldering Zone 1' : 'Workshop Zone' }
            }));
            populateNodeDropdown(deviceList, savedNode);
            return;
          }
        }
      }
    }
  } catch (err) {
    console.warn("[Node Selector] RTDB buffer fallback error:", err);
  }

  // 3. Default fallback jika koneksi belum terbentuk
  populateNodeDropdown([
    { id: 'NODE-MRS01', device_name: 'Soldering Station Node 1', ess_zones: { zone_name: 'Soldering Zone 1' } }
  ], savedNode);
}

// Ekspor ke window global
window.toggleNodeDropdown = toggleNodeDropdown;
window.closeNodeDropdown = closeNodeDropdown;
window.selectNode = selectNode;
window.fetchRegisteredNodes = fetchRegisteredNodes;
window.updateNodeLocationSubtitle = updateNodeLocationSubtitle;
