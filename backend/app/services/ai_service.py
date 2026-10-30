from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any
import google.generativeai as genai
from app.core.config import settings
from app.tools import get_telemetry, get_fleet_summary, get_devices, get_history, get_sop

if settings.GEMINI_API_KEY:
    genai.configure(api_key=settings.GEMINI_API_KEY)

SYSTEM_PROMPT = """
Anda adalah "ESI", asisten kecerdasan buatan resmi untuk Environmental Sensing System (ESS) 
di Laboratorium dan Bengkel Politeknik Kota Malang (POLTEKOM).

Lingkup Pemantauan Sensor Multi-Parameter:
1. Suhu & Kelembapan Udara (DHT22): Menilai kenyamanan termal ruang kerja bengkel.
2. Karbon Monoksida / CO (MQ-7): Aman < 50 PPM, Peringatan/Warning 50-150 PPM, Bahaya/Danger > 150 PPM.
3. Gas Mudah Terbakar & Asap / LPG/Smoke (MQ-2): Aman < 150 PPM, Peringatan/Warning 150-400 PPM, Bahaya/Danger > 400 PPM.

Tugas Utama:
1. Membantu memantau kualitas udara bengkel secara real-time di seluruh area praktikum.
2. Mengevaluasi keamanan area kerja praktikum (las, soldering, mesin bubut/frais, dsb.).
3. Memberikan panduan SOP keselamatan kerja berbasis data ilmiah dan pembacaan sensor riil.

Gaya Komunikasi:
- Profesional, to-the-point, ramah, mengutamakan keselamatan (Safety First).
- Selalu gunakan tools untuk memeriksa data sensor riil sebelum menjawab kondisi bengkel.
- Format rapi dengan Markdown (bullet points, bold untuk angka penting).
- Jika kadar CO > 50 PPM atau Asap/Gas MQ-2 > 150 PPM, beri peringatan tegas untuk menyalakan exhaust fan, membuka ventilasi, memeriksa sumber kebocoran/asap, atau evakuasi jika level DANGER.
"""

def _sanitize_history(raw_history: List[Any]) -> List[Dict[str, Any]]:
    if not raw_history:
        return []

    sanitized: List[Dict[str, Any]] = []
    expected_role = "user"

    for item in raw_history[-10:]:
        role = ""
        content = ""
        if isinstance(item, dict):
            role = item.get("role", "user")
            content = item.get("content") or item.get("text") or item.get("message") or ""
            if not content and "parts" in item:
                parts = item["parts"]
                content = parts[0] if isinstance(parts, list) and parts else str(parts)
        else:
            role = getattr(item, "role", "user")
            content = getattr(item, "content", "")

        content = str(content).strip()
        if not content:
            continue

        normalized_role = "model" if role.lower() in ["model", "assistant", "esi", "bot"] else "user"

        if normalized_role == expected_role:
            sanitized.append({
                "role": normalized_role,
                "parts": [content]
            })
            expected_role = "model" if expected_role == "user" else "user"

    if sanitized and sanitized[-1]["role"] == "user":
        sanitized.pop()

    return sanitized

def ask_esi(
    user_message: str,
    history: Optional[List[Any]] = None,
    active_node_id: Optional[str] = None
) -> Dict[str, Any]:
    if not settings.GEMINI_API_KEY:
        return {
            "reply": "⚠️ [KONFIGURASI]: GEMINI_API_KEY belum disetel di environment backend.",
            "status": "error"
        }

    try:
        tools = [get_telemetry, get_fleet_summary, get_devices, get_history, get_sop]
        tz_wib = timezone(timedelta(hours=settings.TIMEZONE_OFFSET_HOURS))
        current_wib = datetime.now(tz_wib).strftime("%A, %d %B %Y pukul %H:%M:%S WIB")
        target_node = active_node_id if active_node_id else settings.DEFAULT_NODE_ID

        dynamic_prompt = f"""{SYSTEM_PROMPT}

Konteks Operasional & Layar Pengguna Saat Ini:
- Waktu saat ini: {current_wib} (Zona Waktu: WIB / UTC+7).
- Node yang sedang aktif dipantau pengguna di layar: `{target_node}`.
- Jika pengguna bertanya tentang kondisi saat ini tanpa menyebutkan nama node tertentu (misal: "gimana suhunya?", "apakah aman?"), prioritaskan memeriksa node aktif `{target_node}` menggunakan tool `get_telemetry`.
- Jika pengguna bertanya tentang kondisi seluruh bengkel, membandingkan antar ruangan, atau mengecek apakah ada node yang offline/bahaya, gunakan tool `get_fleet_summary`.
- Jika pengguna menanyakan daftar perangkat yang terpasang, letak ruangan, atau metadata node, gunakan tool `get_devices`.
- PERINGATAN WATCHDOG OFFLINE: Perhatikan field `is_online` dan `status_koneksi` pada data sensor! Jika suatu node terdeteksi OFFLINE (`is_online = false`), JANGAN katakan kondisi ruangan saat ini normal/aman berdasarkan angka lama. Beritahu pengguna secara jelas bahwa perangkat tersebut sedang terputus/offline, sebutkan waktu terakhir ia aktif, dan sarankan untuk memeriksa catu daya/koneksi Wi-Fi node tersebut.
- Jika pengguna menanyakan kondisi jam tertentu (misal: "jam 12 tadi siang gimana?"), gunakan parameter `hour_wib=12` pada tool `get_history`.
"""

        model = genai.GenerativeModel(
            model_name=settings.GEMINI_MODEL,
            tools=tools,
            system_instruction=dynamic_prompt
        )

        formatted_history = _sanitize_history(history) if history else []

        try:
            chat = model.start_chat(
                history=formatted_history,
                enable_automatic_function_calling=True
            )
            response = chat.send_message(user_message)
        except Exception as chat_err:
            print(f"[ESI AI WARNING] Gagal start_chat dengan riwayat ({chat_err}), fallback ke chat baru.")
            chat = model.start_chat(enable_automatic_function_calling=True)
            response = chat.send_message(user_message)

        return {
            "reply": response.text,
            "status": "success"
        }
    except Exception as e:
        return {
            "reply": f"Maaf, terjadi kendala saat memproses permintaan: {str(e)}",
            "status": "error"
        }
