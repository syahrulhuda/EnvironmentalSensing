from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any
import google.generativeai as genai
from app.core.config import settings
from app.tools import get_telemetry, get_history, get_sop

if settings.GEMINI_API_KEY:
    genai.configure(api_key=settings.GEMINI_API_KEY)

SYSTEM_PROMPT = """
Anda adalah "ESI", asisten kecerdasan buatan resmi untuk Environmental Sensing System (ESS) 
di Laboratorium dan Bengkel Politeknik Kota Malang (POLTEKOM).

Tugas Utama:
1. Membantu memantau kualitas udara bengkel secara real-time.
2. Mengevaluasi keamanan area kerja praktikum (las, soldering, dsb.).
3. Memberikan panduan SOP keselamatan kerja berbasis data ilmiah dan sensor.

Gaya Komunikasi:
- Profesional, to-the-point, ramah, mengutamakan keselamatan (Safety First).
- Selalu gunakan tools untuk memeriksa data sensor riil sebelum menjawab kondisi bengkel.
- Format rapi dengan Markdown (bullet points, bold untuk angka penting).
- Jika kadar CO > 50 PPM, beri peringatan tegas untuk menyalakan exhaust fan, buka ventilasi, atau evakuasi.
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

def ask_esi(user_message: str, history: Optional[List[Any]] = None) -> Dict[str, Any]:
    if not settings.GEMINI_API_KEY:
        return {
            "reply": "⚠️ [KONFIGURASI]: GEMINI_API_KEY belum disetel di environment backend.",
            "status": "error"
        }

    try:
        tools = [get_telemetry, get_history, get_sop]
        tz_wib = timezone(timedelta(hours=settings.TIMEZONE_OFFSET_HOURS))
        current_wib = datetime.now(tz_wib).strftime("%A, %d %B %Y pukul %H:%M:%S WIB")

        dynamic_prompt = f"""{SYSTEM_PROMPT}

Konteks Waktu Saat Ini:
- Waktu saat ini: {current_wib} (Zona Waktu: WIB / UTC+7).
- Jika pengguna menanyakan kondisi jam tertentu (misal: "jam 12 tadi siang gimana?"), gunakan parameter `hour_wib=12` pada tool `get_history`.
- Field `waktu_lokal_wib` pada tool langsung menunjukkan jam WIB.
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
