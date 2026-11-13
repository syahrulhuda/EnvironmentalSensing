import json
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any, List
from app.core.config import settings
from app.core.database import fetch_rtdb

def _compute_watchdog(ts_ms: Optional[int], tz_wib: timezone) -> Dict[str, Any]:
    """Helper kalkulasi umur heartbeat watchdog (threshold 20 detik)."""
    if not ts_ms:
        return {
            "is_online": False,
            "age_seconds": None,
            "koneksi": "UNKNOWN (Timestamp tidak tersedia)",
            "waktu_lokal_wib": "Unknown"
        }
    
    now_ms = int(datetime.now(timezone.utc).timestamp() * 1000)
    age_seconds = max(0, int((now_ms - ts_ms) / 1000))
    is_online = (age_seconds <= 20)
    
    if is_online:
        koneksi = f"ONLINE (Aktif - {age_seconds}d lalu)"
    elif age_seconds < 60:
        koneksi = f"OFFLINE (Terputus - {age_seconds} detik lalu)"
    elif age_seconds < 3600:
        koneksi = f"OFFLINE (Terputus - {age_seconds // 60} menit lalu)"
    else:
        koneksi = f"OFFLINE (Terputus - {age_seconds // 3600} jam lalu)"

    waktu_wib = datetime.fromtimestamp(ts_ms / 1000.0, tz=tz_wib).strftime("%Y-%m-%d %H:%M:%S WIB")
    
    return {
        "is_online": is_online,
        "age_seconds": age_seconds,
        "koneksi": koneksi,
        "waktu_lokal_wib": waktu_wib
    }

def get_telemetry(device_id: str = settings.DEFAULT_NODE_ID) -> str:
    """
    Mengambil data sensor lingkungan dan kadar gas detik ini dari buffer Firebase RTDB untuk node spesifik.
    Mengembalikan data telemetri real-time beserta status koneksi (ONLINE / OFFLINE via heartbeat watchdog).
    Argumen:
        device_id (str): ID perangkat IoT (contoh: 'NODE-MRS01', 'NODE-02').
    """
    if not device_id or device_id.lower() in ["bengkel", "default", "none", "node-01"]:
        device_id = settings.DEFAULT_NODE_ID

    data = fetch_rtdb()
    if not data:
        return json.dumps({
            "status": "empty",
            "device_id": device_id,
            "is_online": False,
            "koneksi": "OFFLINE (Buffer RTDB kosong)",
            "message": "Buffer Firebase kosong atau gateway belum menerima data."
        })

    matching = [
        item for item in data.values() 
        if isinstance(item, dict) and item.get("node_id", settings.DEFAULT_NODE_ID) == device_id
    ]
    candidates = matching if matching else [item for item in data.values() if isinstance(item, dict)]
    if not candidates:
        return json.dumps({
            "status": "empty",
            "device_id": device_id,
            "is_online": False,
            "koneksi": "OFFLINE (Data tidak ditemukan)",
            "message": f"Tidak ada data telemetri untuk node {device_id} di buffer."
        })

    latest = max(candidates, key=lambda x: x.get("created_at") or 0)
    ts_ms = latest.get("created_at")
    tz_wib = timezone(timedelta(hours=settings.TIMEZONE_OFFSET_HOURS))
    watchdog = _compute_watchdog(ts_ms, tz_wib)
    ts_iso = (
        datetime.fromtimestamp(ts_ms / 1000.0, tz=timezone.utc).isoformat()
        if isinstance(ts_ms, (int, float)) and ts_ms > 0
        else None
    )

    return json.dumps({
        "status": "success",
        "device_id": device_id,
        "is_online": watchdog["is_online"],
        "status_koneksi": watchdog["koneksi"],
        "age_seconds": watchdog["age_seconds"],
        "waktu_lokal_wib": watchdog["waktu_lokal_wib"],
        "created_at": ts_ms,
        "timestamp": ts_iso,
        "temperature_celsius": latest.get("temp"),
        "humidity_percent": latest.get("hum"),
        "mq7_raw_adc": latest.get("mq7_raw"),
        "mq7_voltage": latest.get("mq7_volt"),
        "mq7_co_ppm": latest.get("mq7_ppm"),
        "mq2_raw_adc": latest.get("mq2_raw"),
        "mq2_voltage": latest.get("mq2_volt"),
        "mq2_smoke_ppm": latest.get("mq2_ppm"),
        "status_lingkungan": latest.get("status")
    })

def get_fleet_summary() -> str:
    """
    Mengambil ringkasan kesehatan koneksi dan kondisi lingkungan dari SELURUH node sensor IoT di bengkel.
    Mengelompokkan status seluruh node (Online/Offline, suhu, CO, asap, status peringatan).
    Gunakan tool ini ketika pengguna menanyakan kondisi bengkel secara umum, membandingkan antar ruangan, atau mengecek apakah ada alat yang offline/bahaya.
    """
    data = fetch_rtdb()
    if not data:
        return json.dumps({
            "status": "empty",
            "message": "Buffer Firebase kosong, tidak ada node yang terhubung saat ini."
        })

    # Kelompokkan record terbaru berdasarkan node_id
    grouped: Dict[str, Dict[str, Any]] = {}
    for item in data.values():
        if not isinstance(item, dict):
            continue
        nid = str(item.get("node_id", settings.DEFAULT_NODE_ID))
        cat = item.get("created_at") or 0
        if nid not in grouped or cat > (grouped[nid].get("created_at") or 0):
            grouped[nid] = item

    if not grouped:
        return json.dumps({
            "status": "empty",
            "message": "Tidak ada data node yang valid di buffer."
        })

    tz_wib = timezone(timedelta(hours=settings.TIMEZONE_OFFSET_HOURS))
    nodes_summary: List[Dict[str, Any]] = []
    online_count = 0
    offline_count = 0
    alert_nodes: List[Dict[str, Any]] = []

    for nid, record in grouped.items():
        ts_ms = record.get("created_at")
        watchdog = _compute_watchdog(ts_ms, tz_wib)
        
        is_on = watchdog["is_online"]
        if is_on:
            online_count += 1
        else:
            offline_count += 1

        env_status = record.get("status", "UNKNOWN")
        co_ppm = record.get("mq7_ppm", 0)
        smoke_ppm = record.get("mq2_ppm", 0)

        node_data = {
            "node_id": nid,
            "is_online": is_on,
            "status_koneksi": watchdog["koneksi"],
            "last_seen_wib": watchdog["waktu_lokal_wib"],
            "temperature_celsius": record.get("temp"),
            "humidity_percent": record.get("hum"),
            "mq7_co_ppm": co_ppm,
            "mq2_smoke_ppm": smoke_ppm,
            "status_lingkungan": env_status
        }
        nodes_summary.append(node_data)

        if is_on and (env_status != "NORMAL" or (co_ppm and co_ppm >= 50) or (smoke_ppm and smoke_ppm >= 150)):
            alert_nodes.append({
                "node_id": nid,
                "status_lingkungan": env_status,
                "mq7_co_ppm": co_ppm,
                "mq2_smoke_ppm": smoke_ppm
            })

    return json.dumps({
        "status": "success",
        "total_nodes_in_buffer": len(grouped),
        "online_nodes_count": online_count,
        "offline_nodes_count": offline_count,
        "active_alerts_count": len(alert_nodes),
        "alert_nodes": alert_nodes,
        "fleet_nodes": nodes_summary
    })
