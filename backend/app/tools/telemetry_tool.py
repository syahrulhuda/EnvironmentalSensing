import json
from datetime import datetime, timezone, timedelta
from app.core.config import settings
from app.core.database import fetch_rtdb

def get_telemetry(device_id: str = settings.DEFAULT_NODE_ID) -> str:
    """
    Mengambil data sensor lingkungan dan kadar gas detik ini dari buffer Firebase RTDB.
    Argumen:
        device_id (str): ID perangkat IoT (default: 'NODE-MRS01').
    """
    if not device_id or device_id.lower() in ["bengkel", "default", "none", "node-01"]:
        device_id = settings.DEFAULT_NODE_ID

    data = fetch_rtdb()
    if not data:
        return json.dumps({"status": "empty", "message": "Buffer Firebase kosong atau node belum online."})

    matching = [item for item in data.values() if item.get("node_id", settings.DEFAULT_NODE_ID) == device_id]
    latest = matching[-1] if matching else list(data.values())[-1]

    ts_ms = latest.get("created_at")
    tz_wib = timezone(timedelta(hours=settings.TIMEZONE_OFFSET_HOURS))
    waktu_wib = datetime.fromtimestamp(ts_ms / 1000.0, tz=tz_wib).strftime("%Y-%m-%d %H:%M:%S WIB") if ts_ms else "Unknown"

    return json.dumps({
        "status": "success",
        "device_id": device_id,
        "waktu_lokal_wib": waktu_wib,
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
