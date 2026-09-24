"""
AI Agent Module: Google Gemini Flash dengan ReAct Tool Calling
Mengakses Real-time Telemetry (Firebase RTDB) & Historical Analytics (Supabase PostgreSQL)
Laboratorium Mekatronika POLTEKOM - K3 Environmental Sensing Assistant
"""

import os
import json
import urllib.request
from datetime import datetime, timezone, timedelta
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# =============================================================================
# KONFIGURASI KREDENSIAL & INITIALISASI GEMINI
# =============================================================================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL_NAME = os.getenv("GEMINI_MODEL_NAME", "gemini-flash-lite-latest")
FIREBASE_RTDB_URL = os.getenv(
    "FIREBASE_RTDB_URL",
    "https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json"
)
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://lrnmbhobpymxmzocrfto.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

# Inisialisasi SDK Gemini jika key tersedia
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

# =============================================================================
# DEFINISI TOOLS (FUNGSI YANG BISA DIPANGGIL SECARA OTOMATIS OLEH GEMINI)
# =============================================================================

def get_live_telemetry(device_id: str = "NODE-MRS01") -> str:
    """
    Mengambil data sensor lingkungan dan kadar gas terkini (real-time detik ini) 
    dari Firebase RTDB untuk node tertentu.
    Argumen:
        device_id (str): ID node perangkat IoT (default: "NODE-MRS01"). Selalu gunakan "NODE-MRS01" kecuali user menyebutkan ID node spesifik lain.
    """
    try:
        if not device_id or device_id.lower() in ["bengkel", "bengkel-mekatronika-01", "bengkel_mekatronika_01", "default", "none"]:
            device_id = "NODE-MRS01"

        req = urllib.request.Request(FIREBASE_RTDB_URL, headers={'User-Agent': 'K3-AI-Agent'})
        with urllib.request.urlopen(req, timeout=8) as res:
            if res.status != 200:
                return json.dumps({"status": "error", "message": f"HTTP {res.status} dari Firebase"})
            data = json.loads(res.read().decode('utf-8'))
            if not data:
                return json.dumps({"status": "empty", "message": "Buffer Firebase kosong, node belum mengirim data baru."})

            # Filter data untuk device_id yang diminta, ambil sampel terbaru
            matching_samples = []
            for push_id, item in data.items():
                if item.get("node_id", "NODE-MRS01") == device_id:
                    matching_samples.append(item)

            if not matching_samples:
                # Jika tidak ada yang cocok persis, ambil sampel paling akhir secara umum
                latest = list(data.values())[-1]
            else:
                latest = matching_samples[-1]

            ts_ms = latest.get("created_at")
            waktu_wib = "Unknown"
            if ts_ms:
                dt = datetime.fromtimestamp(ts_ms / 1000.0, tz=timezone(timedelta(hours=7)))
                waktu_wib = dt.strftime("%Y-%m-%d %H:%M:%S WIB")

            return json.dumps({
                "status": "success",
                "device_id": device_id,
                "waktu_lokal_wib": waktu_wib,
                "temperature_celsius": latest.get("temp"),
                "humidity_percent": latest.get("hum"),
                "mq7_raw_adc": latest.get("mq7_raw"),
                "mq7_voltage": latest.get("mq7_volt"),
                "mq7_co_ppm": latest.get("mq7_ppm"),
                "k3_status": latest.get("status")
            })
    except Exception as e:
        return json.dumps({"status": "error", "message": str(e)})


def get_historical_k3_stats(device_id: str = "NODE-MRS01", limit: int = 30, hour_wib: int = None) -> str:
    """
    Mengambil riwayat data agregasi historis per-menit dari database relasional Supabase PostgreSQL.
    Gunakan tool ini ketika user menanyakan kondisi ruangan di waktu lampau, tren data, atau jam tertentu.
    Argumen:
        device_id (str): ID perangkat IoT (default: "NODE-MRS01").
        limit (int): Jumlah baris record menit yang diambil (default: 30).
        hour_wib (int, opsional): Jam tertentu dalam waktu lokal WIB (0 s.d 23) jika user menanyakan jam spesifik.
                                  Contoh: jika user bertanya "jam 12 tadi siang gimana?", isi hour_wib=12.
    """
    try:
        if not device_id or device_id.lower() in ["bengkel", "bengkel-mekatronika-01", "bengkel_mekatronika_01", "default", "none"]:
            device_id = "NODE-MRS01"

        tz_wib = timezone(timedelta(hours=7))
        now_wib = datetime.now(tz_wib)

        if hour_wib is not None:
            # Hitung rentang jam target dalam UTC
            # Jam target WIB hari ini dikonversi ke UTC
            target_dt_start = now_wib.replace(hour=hour_wib, minute=0, second=0, microsecond=0)
            target_dt_end = now_wib.replace(hour=hour_wib, minute=59, second=59, microsecond=0)
            
            # Jika jam yang diminta lebih besar dari jam sekarang, asumsikan hari kemarin
            if target_dt_start > now_wib:
                target_dt_start -= timedelta(days=1)
                target_dt_end -= timedelta(days=1)

            utc_start = target_dt_start.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            utc_end = target_dt_end.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

            endpoint = f"{SUPABASE_URL}/rest/v1/workshop_k3_logs?device_id=eq.{device_id}&recorded_at=gte.{utc_start}&recorded_at=lte.{utc_end}&order=recorded_at.asc&limit={limit}"
        else:
            endpoint = f"{SUPABASE_URL}/rest/v1/workshop_k3_logs?device_id=eq.{device_id}&order=recorded_at.desc&limit={limit}"

        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json"
        }
        req = urllib.request.Request(endpoint, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as res:
            if res.status not in (200, 206):
                return json.dumps({"status": "error", "message": f"HTTP {res.status} dari Supabase"})
            rows = json.loads(res.read().decode('utf-8'))
            if not rows and device_id != "NODE-MRS01":
                return get_historical_k3_stats(device_id="NODE-MRS01", limit=limit, hour_wib=hour_wib)
            if not rows:
                msg = f"Tidak ditemukan catatan data untuk pukul {hour_wib}:00 WIB." if hour_wib is not None else "Belum ada catatan historis di Supabase."
                return json.dumps({"status": "empty", "message": msg})

            # Tambahkan format waktu lokal WIB di setiap record agar model memahami waktu nyata
            formatted_records = []
            for r in rows:
                rec = dict(r)
                if "recorded_at" in rec:
                    dt_utc = datetime.fromisoformat(rec["recorded_at"].replace("Z", "+00:00"))
                    rec["waktu_lokal_wib"] = dt_utc.astimezone(tz_wib).strftime("%H:%M WIB")
                formatted_records.append(rec)

            return json.dumps({
                "status": "success",
                "device_id": device_id,
                "total_records": len(formatted_records),
                "target_hour_wib": hour_wib,
                "records": formatted_records
            })
    except Exception as e:
        return json.dumps({"status": "error", "message": str(e)})


def get_k3_safety_sop(topic: str = "general") -> str:
    """
    Mengambil panduan standar operasional prosedur (SOP) K3 untuk bengkel mekatronika.
    Topik yang tersedia: 'carbon_monoxide', 'welding_fumes', 'soldering', 'general'.
    """
    sop_database = {
        "carbon_monoxide": (
            "SOP K3 GAS CO (OSHA / Permenakertrans No. 5/2018):\n"
            "- Nilai Ambang Batas (NAB) 8 jam: 25 PPM - 50 PPM.\n"
            "- 50 - 100 PPM: Waspada (Ventilasi paksa/exhaust wajib dihidupkan, batasi durasi kerja).\n"
            "- > 100 PPM: BAHAYA KRITIS (Evakuasi area kerja segera, matikan sumber pembakaran, gunakan SCBA/respirator kimia)."
        ),
        "welding_fumes": (
            "SOP K3 PENGELASAN (WELDING STATION):\n"
            "- Wajib menggunakan helm las dengan filter kaca shade sesuai arus listrik.\n"
            "- Wajib menyalakan Local Exhaust Ventilation (LEV) untuk menyedot uap logam dan ozon.\n"
            "- Kenakan sarung tangan kulit las dan apron pelindung percikan api."
        ),
        "soldering": (
            "SOP K3 AREA SOLDERING & PCB ASSEMBLY:\n"
            "- Emisi timbal (Pb) dan uap rosin fluks dapat mengiritasi saluran pernapasan.\n"
            "- Gunakan fume extractor / kipas penyedot asap meja solder.\n"
            "- Jangan makan/minum di area solder dan cuci tangan setelah memegang timah solder."
        ),
        "general": (
            "SOP UMUM LABORATORIUM DAN BENGKEL POLTEKOM:\n"
            "- Kenakan APD standar: Wearpack bengkel, safety shoes, kacamata pelindung.\n"
            "- Pastikan jalur evakuasi bebas rintangan dan APAR siap pakai.\n"
            "- Laporkan segera jika indikator sistem K3 berkedip merah (STATUS DANGER)."
        )
    }
    key = topic.lower()
    for k in sop_database:
        if k in key:
            return sop_database[k]
    return sop_database["general"]

# =============================================================================
# CHAT SESSION & REASONING ENGINE
# =============================================================================

SYSTEM_PROMPT = """
Anda adalah "ESI", asisten kecerdasan buatan (AI) resmi untuk Keselamatan dan Kesehatan Kerja (K3) 
di Laboratorium dan Bengkel Politeknik Kota Malang (POLTEKOM).

Tugas Utama Anda:
1. Membantu teknisi, mahasiswa, dan dosen memantau kualitas udara bengkel secara real-time.
2. Memberikan evaluasi apakah area kerja aman untuk memulai praktikum (misal pengelasan/soldering).
3. Memberikan panduan SOP K3 yang solutif, tegas, dan berbasis data ilmiah ketika terjadi bahaya gas atau asap.

Karakter & Gaya Komunikasi:
- Profesional, to-the-point, ramah, berbasis fakta ilmiah, dan sangat memprioritaskan keselamatan nyawa (Safety First).
- Selalu gunakan tools yang tersedia untuk memeriksa data riil sebelum menjawab pertanyaan terkait kondisi udara bengkel.
- Format jawaban dengan rapi menggunakan Markdown (gunakan bullet points, bold untuk angka penting).
- Jika kadar CO > 50 PPM, beri peringatan tegas untuk menghidupkan exhaust fan, membuka ventilasi, atau evakuasi.
"""

def process_chat_message(user_message: str, history: list = None) -> dict:
    """
    Memproses pesan chat user menggunakan model Gemini Flash dengan ReAct Tool Calling.
    """
    if not GEMINI_API_KEY:
        return {
            "reply": "⚠️ [KONFIGURASI]: GEMINI_API_KEY belum disetel di environment backend. Silakan pasang API Key di pengaturan Render/Backend.",
            "tools_called": []
        }

    try:
        # Gunakan tools yang didefinisikan
        tools_list = [get_live_telemetry, get_historical_k3_stats, get_k3_safety_sop]

        # Injeksi waktu lokal saat ini agar ESI memiliki persepsi waktu yang tepat
        tz_wib = timezone(timedelta(hours=7))
        current_wib = datetime.now(tz_wib).strftime("%A, %d %B %Y pukul %H:%M:%S WIB")

        dynamic_system_instruction = f"""{SYSTEM_PROMPT}

Konteks Waktu & Penanganan Waktu Saat Ini:
- Waktu Anda saat ini: {current_wib} (Zona Waktu: WIB / UTC+7).
- Laboratorium POLTEKOM beroperasi di zona waktu WIB (Indonesia Barat).
- Jika pengguna menanyakan kondisi pada jam tertentu (misal: "jam 12 tadi siang gimana?"), gunakan parameter `hour_wib=12` pada tool `get_historical_k3_stats`.
- Field `waktu_lokal_wib` pada hasil tool sudah langsung menunjukkan jam lokal WIB, gunakan nilai tersebut untuk menjawab pengguna.
"""

        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL_NAME,
            tools=tools_list,
            system_instruction=dynamic_system_instruction
        )

        chat = model.start_chat(enable_automatic_function_calling=True)

        # Muat riwayat jika ada
        if history:
            for item in history:
                # Format sederhana history jika diperlukan
                pass

        response = chat.send_message(user_message)

        return {
            "reply": response.text,
            "status": "success"
        }
    except Exception as e:
        return {
            "reply": f"Maaf, terjadi kendala saat memproses permintaan K3: {str(e)}",
            "status": "error"
        }
