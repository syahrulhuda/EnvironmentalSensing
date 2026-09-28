from datetime import datetime, timezone
from typing import Dict, Any, List, Tuple
from app.core.config import settings
from app.core.database import fetch_rtdb, upsert_logs, patch_rtdb

def aggregate_telemetry(raw_data: Dict[str, Any]) -> List[Dict[str, Any]]:
    buckets: Dict[Tuple[str, str], List[Dict[str, Any]]] = {}

    for item in raw_data.values():
        if not isinstance(item, dict):
            continue
        ts_ms = item.get("created_at")
        temp = item.get("temp")
        hum = item.get("hum")
        raw_adc = item.get("mq7_raw")

        if any(v is None for v in (ts_ms, temp, hum, raw_adc)):
            continue

        try:
            dt = datetime.fromtimestamp(ts_ms / 1000.0, tz=timezone.utc)
            minute_str = dt.strftime("%Y-%m-%dT%H:%M:00+00:00")
            dev_id = str(item.get("node_id", settings.DEFAULT_NODE_ID))
        except Exception:
            continue

        ppm = item.get("mq7_ppm", 5)
        raw_mq2 = item.get("mq2_raw")
        ppm_mq2 = item.get("mq2_ppm")
        status = str(item.get("status", "NORMAL")).upper()

        key = (dev_id, minute_str)
        buckets.setdefault(key, []).append({
            "temp": float(temp),
            "hum": float(hum),
            "raw_adc": int(raw_adc),
            "ppm": int(ppm) if ppm is not None else 5,
            "raw_mq2": int(raw_mq2) if raw_mq2 is not None else None,
            "ppm_mq2": int(ppm_mq2) if ppm_mq2 is not None else None,
            "status": status
        })

    records = []
    for (dev_id, minute_str), samples in sorted(buckets.items()):
        count = len(samples)
        if count == 0:
            continue

        temps = [s["temp"] for s in samples]
        hums = [s["hum"] for s in samples]
        adcs = [s["raw_adc"] for s in samples]
        ppms = [s["ppm"] for s in samples]
        mq2_adcs = [s["raw_mq2"] for s in samples if s["raw_mq2"] is not None]
        mq2_ppms = [s["ppm_mq2"] for s in samples if s["ppm_mq2"] is not None]
        statuses = [s["status"] for s in samples]

        worst = "DANGER" if "DANGER" in statuses else ("WARNING" if "WARNING" in statuses else "NORMAL")

        record = {
            "device_id": dev_id,
            "recorded_at": minute_str,
            "sample_count": count,
            "avg_temp": round(sum(temps) / count, 2),
            "avg_hum": round(sum(hums) / count, 2),
            "avg_mq7_adc": round(sum(adcs) / count, 2),
            "max_mq7_adc": max(adcs),
            "avg_mq7_ppm": round(sum(ppms) / count, 2),
            "max_mq7_ppm": max(ppms),
            "worst_status": worst
        }
        if mq2_adcs:
            record["avg_mq2_adc"] = round(sum(mq2_adcs) / len(mq2_adcs), 2)
            record["max_mq2_adc"] = max(mq2_adcs)
        if mq2_ppms:
            record["avg_mq2_ppm"] = round(sum(mq2_ppms) / len(mq2_ppms), 2)
            record["max_mq2_ppm"] = max(mq2_ppms)

        records.append(record)
    return records

def prune_buffer(raw_data: Dict[str, Any], retention_hours: float = settings.RETENTION_HOURS) -> int:
    now_ts = datetime.now(timezone.utc).timestamp()
    cutoff_ts = now_ts - (retention_hours * 3600.0)

    stale_keys = [
        k for k, v in raw_data.items()
        if isinstance(v, dict) and (v.get("created_at", 0) / 1000.0) < cutoff_ts
    ]

    if not stale_keys:
        return 0

    patch_payload = {k: None for k in stale_keys}
    if patch_rtdb(patch_payload):
        return len(stale_keys)
    return 0

def run_etl() -> bool:
    print(f"[ESS ETL] Siklus dimulai pada {datetime.now(timezone.utc).isoformat()}")
    raw_data = fetch_rtdb()
    if not raw_data:
        print("[ESS ETL] Buffer Firebase kosong.")
        return False

    records = aggregate_telemetry(raw_data)
    if not records:
        print("[ESS ETL] Tidak ada data valid setelah agregasi.")
        return False

    if not upsert_logs(records):
        print("[ESS ETL ERROR] Gagal menyimpan ke Supabase. Pruning dibatalkan.")
        return False

    pruned = prune_buffer(raw_data)
    print(f"[ESS ETL] Sukses mengagregasi {len(records)} baris & memangkas {pruned} data usang.")
    return True
