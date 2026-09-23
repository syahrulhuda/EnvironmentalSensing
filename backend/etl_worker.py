"""
ETL Worker: Firebase RTDB (Hot Buffer) -> Supabase PostgreSQL (Warm Analytics)
Laboratorium Mekatronika POLTEKOM - K3 Monitoring Pipeline
"""

import json
import urllib.request
import urllib.error
from datetime import datetime, timezone
import math
import os

# =============================================================================
# KONFIGURASI ENDPOINT & KREDENSIAL (DIBACA DARI ENVIRONMENT VARIABLES)
# =============================================================================
FIREBASE_RTDB_URL = os.getenv(
    "FIREBASE_RTDB_URL", 
    "https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json"
)
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://lrnmbhobpymxmzocrfto.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")
SUPABASE_REST_ENDPOINT = f"{SUPABASE_URL}/rest/v1/workshop_k3_logs"

# =============================================================================
# 1. EXTRACT (Menarik data dari Firebase RTDB)
# =============================================================================
def extract_from_firebase():
    print("[EXTRACT] Mengambil data dari Firebase RTDB...")
    req = urllib.request.Request(FIREBASE_RTDB_URL, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            if res.status == 200:
                raw = res.read().decode('utf-8')
                data = json.loads(raw)
                if not data:
                    print("[EXTRACT] Buffer kosong.")
                    return {}
                print(f"[EXTRACT] Berhasil mengunduh {len(data)} titik data mentah.")
                return data
            else:
                print(f"[EXTRACT ERROR] HTTP {res.status}")
                return {}
    except Exception as e:
        print(f"[EXTRACT ERROR] Gagal koneksi: {e}")
        return {}

# =============================================================================
# 2. TRANSFORM (Pembersihan, Agregasi 1-Menit, Preservasi Peak K3)
# =============================================================================
def transform_to_minute_aggregates(raw_dict):
    print("[TRANSFORM] Memproses agregasi 1-menitan & preservasi peak K3...")
    
    # Kelompokkan data per bucket menit (format ISO: YYYY-MM-DDTHH:MM:00Z)
    buckets = {} # key: minute_iso_str -> list of samples

    for push_id, item in raw_dict.items():
        ts_ms = item.get("created_at")
        if not ts_ms:
            continue
        
        # Validasi pembacaan DHT & MQ
        temp = item.get("temp")
        hum = item.get("hum")
        raw_adc = item.get("mq7_raw")
        ppm = item.get("mq7_ppm")
        status = item.get("status", "NORMAL")

        # Abaikan record jika DHT null
        if temp is None or hum is None or raw_adc is None:
            continue

        # Konversi timestamp ms ke detik UTC
        dt = datetime.fromtimestamp(ts_ms / 1000.0, tz=timezone.utc)
        # Normalisasi ke awal menit (detik = 0)
        bucket_key = dt.replace(second=0, microsecond=0).isoformat()

        if bucket_key not in buckets:
            buckets[bucket_key] = []

        buckets[bucket_key].append({
            "temp": float(temp),
            "hum": float(hum),
            "raw_adc": int(raw_adc),
            "ppm": int(ppm) if ppm is not None else 5,
            "status": status
        })

    # Hitung statistik agregat per menit
    transformed_records = []
    
    for bucket_time, samples in sorted(buckets.items()):
        count = len(samples)
        if count == 0:
            continue

        temps = [s["temp"] for s in samples]
        hums = [s["hum"] for s in samples]
        adcs = [s["raw_adc"] for s in samples]
        ppms = [s["ppm"] for s in samples]
        statuses = [s["status"] for s in samples]

        # Tentukan status terburuk dalam 1 menit
        if "DANGER" in statuses:
            worst = "DANGER"
        elif "WARNING" in statuses:
            worst = "WARNING"
        else:
            worst = "NORMAL"

        record = {
            "recorded_at": bucket_time,
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

    print(f"[TRANSFORM] Berhasil memadatkan data menjadi {len(transformed_records)} baris agregat historis.")
    return transformed_records

# =============================================================================
# 3. LOAD (Mengirim batch data ke Supabase PostgreSQL)
# =============================================================================
def load_to_supabase(records):
    if not records:
        print("[LOAD] Tidak ada data untuk dikirim.")
        return False

    print(f"[LOAD] Mengirim {len(records)} baris ke Supabase (tabel workshop_k3_logs)...")
    
    payload_bytes = json.dumps(records).encode('utf-8')
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates" # Upsert jika recorded_at sudah ada
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
                print(f"[LOAD SUKSES] Berhasil menyimpan data ke Supabase (HTTP {res.status})!")
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
# RUN ETL PIPELINE
# =============================================================================
if __name__ == "__main__":
    print("==================================================")
    print("   MEMULAI EKSEKUSI PIPELINE ETL FIREBASE -> SUPABASE")
    print("==================================================")
    
    # 1. Extract
    raw_data = extract_from_firebase()
    
    # 2. Transform
    if raw_data:
        clean_records = transform_to_minute_aggregates(raw_data)
        
        # 3. Load
        success = load_to_supabase(clean_records)
        
        if success:
            print("\n[OK] PIPELINE ETL SELESAI DENGAN SUKSES!")
            print(f"     {len(raw_data)} data mentah diringkas menjadi {len(clean_records)} baris di PostgreSQL.")
    print("==================================================")
