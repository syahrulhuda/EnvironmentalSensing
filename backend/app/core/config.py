import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

def _normalize_rtdb_url(url: str) -> str:
    url = url.strip()
    if not url.endswith(".json"):
        return url.rstrip("/") + "/telemetry/buffer.json"
    return url

_raw_rtdb = os.getenv(
    "FIREBASE_RTDB_URL",
    "https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json"
)

@dataclass(frozen=True)
class Settings:
    PROJECT_NAME: str = "Environmental Sensing System"
    APP_CODE: str = "ESS"
    AGENT_NAME: str = "ESI"

    FIREBASE_RTDB_URL: str = _normalize_rtdb_url(_raw_rtdb)
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://lrnmbhobpymxmzocrfto.supabase.co")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

    TABLE_LOGS: str = os.getenv("TABLE_LOGS", "ess_logs")
    TABLE_ANOMALIES: str = os.getenv("TABLE_ANOMALIES", "ess_anomalies")
    TABLE_DEVICES: str = os.getenv("TABLE_DEVICES", "ess_devices")
    TABLE_ZONES: str = os.getenv("TABLE_ZONES", "ess_zones")

    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL_NAME", "gemini-flash-lite-latest")

    DEFAULT_NODE_ID: str = "NODE-MRS01"
    RETENTION_HOURS: float = 2.0
    TIMEZONE_OFFSET_HOURS: int = 7

    PORT: int = int(os.getenv("PORT", 8000))
    HOST: str = os.getenv("HOST", "0.0.0.0")
    ADMIN_API_KEY: str = os.getenv("ADMIN_API_KEY", "ess-secret-admin-key-2026")

settings = Settings()
