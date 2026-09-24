"""
ETL Worker: Multi-Node Firebase RTDB (Hot Buffer) -> Supabase PostgreSQL (Warm Analytics)
Mendukung Multi-Device, Agregasi 1-Menitan, dan FIFO Continuous Sliding Window 2 Jam
Laboratorium Mekatronika POLTEKOM - K3 Monitoring Pipeline
"""

import json
import urllib.request
import urllib.error
from datetime import datetime, timezone
import os

# =============================================================================
# KONFIGURASI ENDPOINT & KREDENSIAL
# =============================================================================
# Baca dari environment variables, dengan fallback file .env lokal
FIREBASE_RTDB_URL = os.getenv(
    "FIREBASE_RTDB_URL", 
    "https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json"
)
SUPABASE_URL = os.getenv(
    "SUPABASE_URL", 
    "https://lrnmbhobpymxmzocrfto.supabase.co"
)
SUPABASE_KEY = os.getenv(
    "SUPABASE_KEY", 
    "sb_secret_hRgIlTrbGIwPl_iM87P2xg_uMB82nAW"
)
SUPABASE_REST_ENDPOINT = f"{SUPABASE_URL}/rest/v1/workshop_k3_logs"

# Konfigurasi Retensi Buffer (Sliding Window)
RETENTION_HOURS = 2.0

# =============================================================================
# 1. EXTRACT (Menarik data dari Firebase RTDB)
# =============================================================================
def extract_from_firebase():
    print("[1/4 EXTRACT] Mengunduh data dari Firebase RTDB...")
    req = urllib.request.Request(FIREBASE_RTDB_URL, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            if res.status == 200:
                raw = res.read().decode('utf-8')
                data = json.loads(raw)
                if not data:
                    print("[EXTRACT] Buffer kosong, tidak ada data baru.")
                    return {}
                print(f"[EXTRACT] Berhasil mengunduh {len(data)} titik data mentah.")
                return data
            else:
                print(f"[EXTRACT ERROR] HTTP {res.status}")
                return {}
    except Exception as e:
        print(f"[EXTRACT ERROR] Gagal koneksi ke Firebase: {e}")
        return {}

# =============================================================================
# 2. TRANSFORM (Multi-Node & 1-Minute Aggregation dengan Peak K3)
# =============================================================================
def transform_to_multi_node_aggregates(raw_dict):
    print("[2/4 TRANSFORM] Memproses agregasi 2-dimensi (Device ID + Menit)...")
    
    # Pengelompokan: key = (device_id, minute_iso_str) -> list of samples
    buckets = {}

    for push_id, item in raw_dict.items():
        ts_ms = item.get("created_at")
        if not ts_ms:
            continue
        
        # Ekstrak identitas device (fallback default ke NODE-MRS01)
        device_id = item.get("node_id", "NODE-MRS01")
        
        # Validasi pembacaan sensor
        temp = item.get("temp")
        hum = item.get("hum")
        raw_adc = item.get("mq7_raw")
        ppm = item.get("mq7_ppm")
        status = item.get("status", "NORMAL")

        # Abaikan record jika pembacaan sensor tidak valid / null
        if temp is None or hum is None or raw_adc is None:
            continue

        # Normalisasi waktu ke awal menit (detik = 0) dalam format UTC ISO-8601
        dt = datetime.fromtimestamp(ts_ms / 1000.0, tz=timezone.utc)
        bucket_minute = dt.replace(second=0, microsecond=0).isoformat()

        bucket_key = (device_id, bucket_minute)

        if bucket_key not in buckets:
            buckets[bucket_key] = []

        buckets[bucket_key].append({
            "temp": float(temp),
            "hum": float(hum),
            "raw_adc": int(raw_adc),
            "ppm": int(ppm) if ppm is not None else 5,
            "status": status
        })

    # Hitung nilai statistik per device per menit
    transformed_records = []
    
    for (dev_id, minute_str), samples in sorted(buckets.items()):
        count = len(samples)
        if count == 0:
            continue

        temps = [s["temp"] for s in samples]
        hums = [s["hum"] for s in samples]
        adcs = [s["raw_adc"] for s in samples]
        ppms = [s["ppm"] for s in samples]
        statuses = [s["status"] for s in samples]

        # Tentukan status K3 terburuk dalam 1 menit
        if "DANGER" in statuses:
            worst = "DANGER"
        elif "WARNING" in statuses:
            worst = "WARNING"
        else:
            worst = "NORMAL"

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
        transformed_records.append(record)

    # Deteksi perangkat unik yang aktif
    unique_devices = list(set([r["device_id"] for r in transformed_records]))
    print(f"[TRANSFORM] Berhasil memadatkan menjadi {len(transformed_records)} baris agregat.")
    print(f"            Perangkat aktif terdeteksi: {unique_devices}")
    return transformed_records

# =============================================================================
# 3. LOAD (Mengirim batch data ke Supabase PostgreSQL)
# =============================================================================
def load_to_supabase(records):
    if not records:
        print("[3/4 LOAD] Lewati penyimpanan: Tidak ada data valid.")
        return False

    print(f"[3/4 LOAD] Mengirim {len(records)} baris ke Supabase (tabel workshop_k3_logs)...")
    
    payload_bytes = json.dumps(records).encode('utf-8')
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates" # Upsert berdasarkan (device_id, recorded_at)
    }

    req = urllib.request.Request(
        SUPABASE_REST_ENDPOINT,
        data=payload_bytes,
        headers=headers,
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            if res.status in (200, 201):
                print(f"[LOAD SUKSES] Data berhasil disimpan permanen ke Supabase (HTTP {res.status})!")
                return True
            else:
                print(f"[LOAD STATUS] HTTP {res.status}")
                return False
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode('utf-8', errors='ignore')
        print(f"[LOAD ERROR] Gagal mengirim ke Supabase (HTTP {e.code}): {err_msg}")
        return False
    except Exception as e:
        print(f"[LOAD ERROR] Error koneksi: {e}")
        return False

# =============================================================================
# 4. PRUNING SLIDING WINDOW (Memangkas data > 2 jam di Firebase RTDB)
# =============================================================================
def prune_rtdb_sliding_window(raw_dict, retention_hours=RETENTION_HOURS):
    print(f"[4/4 PRUNE] Memeriksa data lebih tua dari {retention_hours} jam di RTDB...")
    
    now_ms = datetime.now(timezone.utc).timestamp() * 1000
    cutoff_ms = now_ms - (retention_hours * 60 * 60 * 1000)

    # Kumpulkan Push-ID yang usianya melebihi cutoff
    keys_to_delete = {}
    for push_id, item in raw_dict.items():
        created_at = item.get("created_at", 0)
        if created_at > 0 and created_at < cutoff_ms:
            keys_to_delete[push_id] = None # Nilai null pada PATCH Firebase berarti DELETE

    if not keys_to_delete:
        print(f"[PRUNE] Seluruh data berada dalam jendela {retention_hours} jam terakhir. 0 data dihapus.")
        return True

    print(f"[PRUNE] Menghapus {len(keys_to_delete)} titik data usang dari RTDB...")
    patch_payload = json.dumps(keys_to_delete).encode('utf-8')
    req = urllib.request.Request(
        FIREBASE_RTDB_URL,
        data=patch_payload,
        headers={
            "Content-Type": "application/json",
            "X-HTTP-Method-Override": "PATCH"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            if res.status == 200:
                print(f"[PRUNE SUKSES] Berhasil memangkas {len(keys_to_delete)} data. RTDB tetap ramping!")
                return True
            else:
                print(f"[PRUNE STATUS] HTTP {res.status}")
                return False
    except Exception as e:
        print(f"[PRUNE ERROR] Gagal memangkas data RTDB: {e}")
        return False

# =============================================================================
# RUN PIPELINE LENGKAP
# =============================================================================
def run_full_etl():
    print("==================================================================")
    print("   MEMULAI SIKLUS ETL K3 (FIREBASE -> SUPABASE + SLIDING PRUNE)   ")
    print(f"   Waktu Eksekusi: {datetime.now(timezone.utc).isoformat()}     ")
    print("==================================================================")
    
    # 1. Extract
    raw_data = extract_from_firebase()
    if not raw_data:
        print("[SELESAI] Tidak ada data mentah yang perlu diproses.\n")
        return

    # 2. Transform
    clean_records = transform_to_multi_node_aggregates(raw_data)
    if not clean_records:
        print("[SELESAI] Tidak ada data valid setelah transformasi.\n")
        return

    # 3. Load
    load_success = load_to_supabase(clean_records)

    # 4. Prune (HANYA dijalankan jika proses Load berhasil - Fail-safe rule)
    if load_success:
        prune_rtdb_sliding_window(raw_data, retention_hours=RETENTION_HOURS)
        print("\n[OK] SIKLUS ETL SELESAI DENGAN SUKSES 100%!")
    else:
        print("\n[PERINGATAN] Pruning RTDB dibatalkan demi keamanan karena proses Load gagal!")
    
    print("==================================================================\n")

if __name__ == "__main__":
    run_full_etl()
