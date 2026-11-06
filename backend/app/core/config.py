import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

def _normalize_rtdb_url(url: str) -> str:
    url = url.strip()
    if not url.endswith(".json"):
        return url.rstrip("/") + "/telemetry/buffer.json"
    return url

_raw_rtdb = os.getenv("FIREBASE_RTDB_URL", "").strip()
_raw_supabase = os.getenv("SUPABASE_URL", "").strip()

# Fail-Fast Validation (TD-B03): Backend menolak start jika variabel kritis tidak disuplai
_missing_vars = []
if not _raw_rtdb:
    _missing_vars.append("FIREBASE_RTDB_URL")
if not _raw_supabase:
    _missing_vars.append("SUPABASE_URL")

if _missing_vars:
    # Izinkan mock fallback hanya saat pengujian sandbox CI otomatis
    if os.getenv("CI") or os.getenv("ESS_TEST_MODE"):
        _raw_rtdb = _raw_rtdb or "https://mock-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json"
        _raw_supabase = _raw_supabase or "https://mock-supabase.supabase.co"
    else:
        raise ValueError(
            f"[ESS CONFIG FATAL] Variabel lingkungan wajib berikut tidak disetel di .env: {', '.join(_missing_vars)}. "
            f"Backend menolak booting dalam status unconfigured untuk mencegah silent failure / salah database. "
            f"Silakan salin .env.example menjadi .env dan isi kredensial dengan benar."
        )

@dataclass(frozen=True)
class Settings:
    PROJECT_NAME: str = "Environmental Sensing System"
    APP_CODE: str = "ESS"
    AGENT_NAME: str = "ESI"

    FIREBASE_RTDB_URL: str = _normalize_rtdb_url(_raw_rtdb)
    # Autentikasi Firebase RTDB via Database Secret / Auth Token (SEC-02)
    FIREBASE_RTDB_AUTH: str = os.getenv("FIREBASE_RTDB_AUTH", "").strip()

    SUPABASE_URL: str = _raw_supabase
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "").strip()

    TABLE_LOGS: str = os.getenv("TABLE_LOGS", "ess_logs")
    TABLE_ANOMALIES: str = os.getenv("TABLE_ANOMALIES", "ess_anomalies")
    TABLE_DEVICES: str = os.getenv("TABLE_DEVICES", "ess_devices")
    TABLE_ZONES: str = os.getenv("TABLE_ZONES", "ess_zones")

    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "").strip()
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL_NAME", "gemini-flash-lite-latest")

    DEFAULT_NODE_ID: str = "NODE-MRS01"
    RETENTION_HOURS: float = 2.0
    TIMEZONE_OFFSET_HOURS: int = 7

    PORT: int = int(os.getenv("PORT", 8000))
    HOST: str = os.getenv("HOST", "0.0.0.0")
    ADMIN_API_KEY: str = os.getenv("ADMIN_API_KEY", "ess-secret-admin-key-2026")
    CHAT_RATE_LIMIT_PER_MINUTE: int = int(os.getenv("CHAT_RATE_LIMIT_PER_MINUTE", "15"))

    # Mobile In-App OTA Update Engine (DEVOPS-03 / DEVOPS-04)
    APP_LATEST_VERSION: str = os.getenv("APP_LATEST_VERSION", "2.2.2")
    APP_MIN_REQUIRED_VERSION: str = os.getenv("APP_MIN_REQUIRED_VERSION", "1.0.0")
    APP_DOWNLOAD_URL: str = os.getenv(
        "APP_DOWNLOAD_URL",
        "https://github.com/syahrulhuda/EnvironmentalSensing/releases/latest/download/app-release.apk"
    )
    APP_RELEASE_NOTES: str = os.getenv(
        "APP_RELEASE_NOTES",
        "Pembaruan ESS v2.2.2: Keyboard-aware bottom sheet pada chat ESI (anti-tertutup) dan Markdown Renderer penuh untuk bubble teks AI."
    )
    APP_FORCE_UPDATE: bool = os.getenv("APP_FORCE_UPDATE", "false").lower() in ("true", "1", "yes")

    def get_rtdb_url(self) -> str:
        """
        Mengembalikan URL Firebase RTDB yang aman (SEC-02).
        Menyisipkan query parameter ?auth=<secret> jika FIREBASE_RTDB_AUTH disetel.
        """
        if self.FIREBASE_RTDB_AUTH:
            sep = "&" if "?" in self.FIREBASE_RTDB_URL else "?"
            return f"{self.FIREBASE_RTDB_URL}{sep}auth={self.FIREBASE_RTDB_AUTH}"
        return self.FIREBASE_RTDB_URL

settings = Settings()
