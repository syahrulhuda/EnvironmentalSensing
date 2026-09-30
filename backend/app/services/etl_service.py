import re
from datetime import datetime, timezone
from typing import Dict, Any, List, Tuple
from app.core.config import settings
from app.core.database import (
    fetch_rtdb, upsert_logs, patch_rtdb,
    upsert_anomaly, query_active_anomaly
)

def calc_hazard_priority(mq7_ppm: int, mq2_ppm: int) -> Tuple[str, int, float]:
    """
    Menghitung gas paling berbahaya berdasarkan rasio ambang batas K3:
    - MQ-7 (CO): Warn=50, Danger=150
    - MQ-2 (Gas/Smoke): Warn=150, Danger=400
    Returns: (sensor_name, peak_ppm, hazard_score)
    """
    tier_mq7 = 2 if mq7_ppm >= 150 else (1 if mq7_ppm >= 50 else 0)
    tier_mq2 = 2 if mq2_ppm >= 400 else (1 if mq2_ppm >= 150 else 0)
    h_mq7 = mq7_ppm / 50.0
    h_mq2 = mq2_ppm / 150.0

    if tier_mq7 > tier_mq2:
        return "MQ-7", mq7_ppm, tier_mq7 * 100.0 + h_mq7
    elif tier_mq2 > tier_mq7:
        return "MQ-2", mq2_ppm, tier_mq2 * 100.0 + h_mq2
    else:
        if h_mq7 >= h_mq2:
            return "MQ-7", mq7_ppm, tier_mq7 * 100.0 + h_mq7
        else:
            return "MQ-2", mq2_ppm, tier_mq2 * 100.0 + h_mq2

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

def process_incident_sessions(upserted_rows: List[Dict[str, Any]]) -> None:
    if not upserted_rows:
        return

    sorted_logs = sorted(upserted_rows, key=lambda x: x.get("recorded_at", ""))
    active_anomaly = query_active_anomaly()

    for log in sorted_logs:
        status = log.get("worst_status", "NORMAL")
        peak_co = log.get("max_mq7_ppm") or 0
        peak_gas = log.get("max_mq2_ppm") or 0
        log_id = log["id"]
        rec_at = log["recorded_at"]

        if status in ("WARNING", "DANGER"):
            sensor, peak_val, _ = calc_hazard_priority(peak_co, peak_gas)
            if active_anomaly is None:
                desc = f"{status}: PEAK {peak_val} (MQ-7: {peak_co}, MQ-2: {peak_gas})"
                new_anomaly = {
                    "id": log_id,
                    "incident_type": status,
                    "peak_log_id": log_id,
                    "end_log_id": None,
                    "duration_minutes": 1,
                    "peak_ppm": peak_val,
                    "description": desc,
                    "resolved": False,
                    "started_at": rec_at,
                    "ended_at": None,
                    "created_at": rec_at
                }
                if upsert_anomaly(new_anomaly):
                    active_anomaly = new_anomaly
                    print(f"[ESS ETL] Insiden baru #{log_id} ({status}) dibuka pada {rec_at} [Peak: {peak_val} PPM by {sensor}].")
            else:
                updated = False
                match = re.search(r"MQ-7:\s*(\d+),\s*MQ-2:\s*(\d+)", active_anomaly.get("description", ""))
                prev_mq7 = int(match.group(1)) if match else 0
                prev_mq2 = int(match.group(2)) if match else 0
                
                sess_mq7 = max(prev_mq7, peak_co)
                sess_mq2 = max(prev_mq2, peak_gas)
                win_sensor, new_peak, new_score = calc_hazard_priority(sess_mq7, sess_mq2)
                
                _, _, old_score = calc_hazard_priority(prev_mq7, prev_mq2)
                if new_score > old_score:
                    active_anomaly["peak_ppm"] = new_peak
                    active_anomaly["peak_log_id"] = log_id
                    updated = True

                if status == "DANGER" and active_anomaly.get("incident_type") != "DANGER":
                    active_anomaly["incident_type"] = "DANGER"
                    updated = True

                new_desc = f"{active_anomaly['incident_type']}: PEAK {new_peak} (MQ-7: {sess_mq7}, MQ-2: {sess_mq2})"
                if active_anomaly.get("description") != new_desc:
                    active_anomaly["description"] = new_desc
                    updated = True

                try:
                    start_str = active_anomaly.get("started_at") or active_anomaly.get("created_at")
                    dt_start = datetime.fromisoformat(start_str.replace("Z", "+00:00"))
                    dt_cur = datetime.fromisoformat(rec_at.replace("Z", "+00:00"))
                    dur = max(1, int((dt_cur - dt_start).total_seconds() / 60.0) + 1)
                    active_anomaly["duration_minutes"] = dur
                    updated = True
                except Exception:
                    pass

                if updated:
                    upsert_anomaly(active_anomaly)
        else:
            if active_anomaly is not None:
                active_anomaly["end_log_id"] = log_id
                active_anomaly["ended_at"] = rec_at
                try:
                    start_str = active_anomaly.get("started_at") or active_anomaly.get("created_at")
                    dt_start = datetime.fromisoformat(start_str.replace("Z", "+00:00"))
                    dt_end = datetime.fromisoformat(rec_at.replace("Z", "+00:00"))
                    dur = max(1, int((dt_end - dt_start).total_seconds() / 60.0))
                    active_anomaly["duration_minutes"] = dur
                except Exception:
                    pass

                upsert_anomaly(active_anomaly)
                print(f"[ESS ETL] Insiden #{active_anomaly['id']} resmi ditutup (udara normal kembali pada {rec_at}, durasi {active_anomaly.get('duration_minutes')} m).")
                active_anomaly = None

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

    upserted_rows = upsert_logs(records)
    if not upserted_rows:
        print("[ESS ETL ERROR] Gagal menyimpan ke Supabase. Pruning dibatalkan.")
        return False

    process_incident_sessions(upserted_rows)

    pruned = prune_buffer(raw_data)
    print(f"[ESS ETL] Sukses mengagregasi {len(records)} baris & memangkas {pruned} data usang.")
    return True
