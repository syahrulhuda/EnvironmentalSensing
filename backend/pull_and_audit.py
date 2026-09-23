"""
Script Audit & Analisis Data Telemetri Firebase RTDB
Laboratorium Mekatronika POLTEKOM - K3 Environmental Sensing
"""

import json
import urllib.request
import datetime
import math

DATABASE_URL = "https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json"

def fetch_telemetry_data():
    print(f"[1/4] Mengunduh data dari Firebase RTDB: {DATABASE_URL} ...")
    req = urllib.request.Request(
        DATABASE_URL, 
        headers={'User-Agent': 'Mozilla/5.0'}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            if response.status == 200:
                raw_data = response.read().decode('utf-8')
                data = json.loads(raw_data)
                return data
            else:
                print(f"[ERROR] HTTP Status: {response.status}")
                return None
    except Exception as e:
        print(f"[ERROR] Gagal mengunduh: {e}")
        return None

def audit_and_analyze(data):
    if not data:
        print("[AUDIT] Data di Firebase kosong atau belum ada pengiriman.")
        return

    records = list(data.values())
    total_samples = len(records)
    print(f"\n[2/4] Berhasil mengekstrak {total_samples} data points.")

    temps = []
    hums = []
    mq7_adcs = []
    mq7_ppms = []
    statuses = {"NORMAL": 0, "WARNING": 0, "DANGER": 0, "OTHER": 0}
    null_dht_count = 0
    timestamps = []

    for r in records:
        # DHT22 validation
        t = r.get("temp")
        h = r.get("hum")
        if t is None or h is None:
            null_dht_count += 1
        else:
            temps.append(float(t))
            hums.append(float(h))

        # MQ-7 validation
        raw_adc = r.get("mq7_raw")
        ppm = r.get("mq7_ppm")
        if raw_adc is not None:
            mq7_adcs.append(int(raw_adc))
        if ppm is not None:
            mq7_ppms.append(int(ppm))

        # Status counts
        st = r.get("status", "OTHER")
        if st in statuses:
            statuses[st] += 1
        else:
            statuses["OTHER"] += 1

        # Timestamps
        ts = r.get("created_at")
        if ts:
            timestamps.append(ts)

    # Sort timestamps to calculate sampling intervals
    timestamps.sort()
    gaps = []
    for i in range(1, len(timestamps)):
        dt_sec = (timestamps[i] - timestamps[i-1]) / 1000.0
        if dt_sec > 6.0: # Normal interval is ~3 seconds, >6s indicates dropped packet or Wi-Fi reconnect
            gaps.append(dt_sec)

    def stats(arr):
        if not arr:
            return {"min": 0, "max": 0, "avg": 0, "std": 0}
        avg = sum(arr) / len(arr)
        variance = sum((x - avg) ** 2 for x in arr) / len(arr)
        return {
            "min": min(arr),
            "max": max(arr),
            "avg": round(avg, 2),
            "std": round(math.sqrt(variance), 2)
        }

    temp_stat = stats(temps)
    hum_stat = stats(hums)
    adc_stat = stats(mq7_adcs)
    ppm_stat = stats(mq7_ppms)

    print("\n[3/4] ================== LAPORAN AUDIT ANOMALI ==================")
    print(f"1. INTEGRITAS PENGIRIMAN DATA:")
    print(f"   - Total Titik Data Diterima : {total_samples} sampel")
    print(f"   - DHT22 Gagal Baca (Null)   : {null_dht_count} ({round(null_dht_count/max(1, total_samples)*100, 2)}%)")
    print(f"   - Jeda Koneksi (>6 detik)   : {len(gaps)} kali lonjakan jeda (Max gap: {max(gaps) if gaps else 0} detik)")
    
    print(f"\n2. STATISTIK SUHU & KELEMBAPAN (DHT22):")
    print(f"   - Suhu (°C)       : Min={temp_stat['min']} | Max={temp_stat['max']} | Rata-rata={temp_stat['avg']} | Deviasi={temp_stat['std']}")
    print(f"   - Kelembapan (%)  : Min={hum_stat['min']} | Max={hum_stat['max']} | Rata-rata={hum_stat['avg']} | Deviasi={hum_stat['std']}")

    print(f"\n3. STATISTIK SENSOR GAS CO (MQ-7):")
    print(f"   - Raw ADC (0-4095): Min={adc_stat['min']} | Max={adc_stat['max']} | Rata-rata={adc_stat['avg']} | Deviasi={adc_stat['std']}")
    print(f"   - Estimasi CO PPM : Min={ppm_stat['min']} | Max={ppm_stat['max']} | Rata-rata={ppm_stat['avg']} | Deviasi={ppm_stat['std']}")

    print(f"\n4. DISTRIBUSI STATUS K3:")
    print(f"   - NORMAL  : {statuses['NORMAL']} sampel")
    print(f"   - WARNING : {statuses['WARNING']} sampel")
    print(f"   - DANGER  : {statuses['DANGER']} sampel")

    # Kesimpulan Anomali
    print("\n[4/4] =================== KESIMPULAN KELAYAKAN ===================")
    anomalies = []
    if null_dht_count > 0:
        anomalies.append(f"Terdapat {null_dht_count} error pembacaan sensor DHT22 (cek kelonggaran kabel).")
    if len(gaps) > (total_samples * 0.05):
        anomalies.append("Koneksi Wi-Fi kurang stabil (>5% paket mengalami jeda pengiriman).")
    if adc_stat['std'] > 150:
        anomalies.append("Terjadi fluktuasi besar pada ADC MQ-7 (kemungkinan ada hembusan gas atau gangguan supply daya).")

    if not anomalies:
        print("[OK] HASIL: DATA SANGAT BERSIH & STABIL. Tidak ditemukan anomali signifikan.")
        print("     Sistem siap dipindahkan ke pipeline agregasi Supabase.")
    else:
        print("[PERINGATAN] CATATAN ANOMALI DITEMUKAN:")
        for a in anomalies:
            print(f"   - {a}")
    print("==================================================================")

if __name__ == "__main__":
    data = fetch_telemetry_data()
    audit_and_analyze(data)
