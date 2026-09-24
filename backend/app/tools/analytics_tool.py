import json
from datetime import datetime, timezone, timedelta
from typing import Optional
from app.core.config import settings
from app.core.database import query_logs

def get_history(
    device_id: str = settings.DEFAULT_NODE_ID,
    limit: int = 30,
    hour_wib: Optional[int] = None
) -> str:
    """
    Mengambil riwayat data agregasi menit lampau dari database Supabase PostgreSQL.
    Argumen:
        device_id (str): ID perangkat IoT (default: 'NODE-MRS01').
        limit (int): Jumlah baris menit (default: 30).
        hour_wib (int, opsional): Jam tertentu dalam format WIB (0-23) jika menanyakan jam spesifik (misal: 12 untuk jam 12 siang).
    """
    if not device_id or device_id.lower() in ["bengkel", "default", "none", "node-01"]:
        device_id = settings.DEFAULT_NODE_ID

    tz_wib = timezone(timedelta(hours=settings.TIMEZONE_OFFSET_HOURS))
    now_wib = datetime.now(tz_wib)
    utc_start, utc_end = None, None

    limit = int(limit)
    if hour_wib is not None:
        h = int(hour_wib)
        target_start = now_wib.replace(hour=h, minute=0, second=0, microsecond=0)
        target_end = now_wib.replace(hour=h, minute=59, second=59, microsecond=0)
        if target_start > now_wib:
            target_start -= timedelta(days=1)
            target_end -= timedelta(days=1)
        utc_start = target_start.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        utc_end = target_end.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    rows = query_logs(device_id=device_id, limit=limit, utc_start=utc_start, utc_end=utc_end)
    if not rows and device_id != settings.DEFAULT_NODE_ID:
        rows = query_logs(device_id=settings.DEFAULT_NODE_ID, limit=limit, utc_start=utc_start, utc_end=utc_end)

    if not rows:
        msg = f"Tidak ditemukan catatan data untuk pukul {hour_wib}:00 WIB." if hour_wib is not None else "Belum ada catatan historis di database."
        return json.dumps({"status": "empty", "message": msg})

    formatted = []
    for r in rows:
        item = dict(r)
        if "recorded_at" in item:
            dt = datetime.fromisoformat(item["recorded_at"].replace("Z", "+00:00"))
            item["waktu_lokal_wib"] = dt.astimezone(tz_wib).strftime("%H:%M WIB")
        formatted.append(item)

    return json.dumps({
        "status": "success",
        "device_id": device_id,
        "total_records": len(formatted),
        "target_hour_wib": hour_wib,
        "records": formatted
    })
