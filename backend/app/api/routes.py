import json
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Header, Depends, status
from pydantic import BaseModel, Field
from app.core.config import settings
from app.core.rate_limiter import chat_rate_limiter
from app.services.ai_service import ask_esi
from app.services.etl_service import run_etl
from app.tools.telemetry_tool import get_telemetry
from app.core.database import query_logs, query_devices

router = APIRouter()

class ChatMessage(BaseModel):
    role: str = Field(..., description="Peran pesan: 'user' atau 'model' / 'assistant'", example="user")
    content: str = Field(..., description="Isi teks pesan", example="Bagaimana kondisi gas CO sekarang?")

class ChatRequest(BaseModel):
    message: str = Field(..., example="Bagaimana kualitas udara bengkel saat ini?")
    history: Optional[List[ChatMessage]] = Field(default=None, description="Riwayat obrolan bertingkat")
    active_node_id: Optional[str] = Field(default=None, description="ID node IoT yang sedang dipantau di layar pengguna", example="NODE-MRS01")


class ChatResponse(BaseModel):
    reply: str
    status: str
    timestamp: str

class HealthResponse(BaseModel):
    status: str
    app: str
    version: str
    timestamp: str

class AppVersionResponse(BaseModel):
    latest_version: str = Field(..., description="Versi rilis APK terbaru", example="1.2.0")
    min_required_version: str = Field(..., description="Versi minimum yang wajib digunakan", example="1.0.0")
    download_url: str = Field(..., description="URL unduhan langsung file APK", example="https://github.com/syahrulhuda/EnvironmentalSensing/releases/latest/download/app-release.apk")
    release_notes: str = Field(..., description="Catatan rilis / changelog pembaruan", example="Pembaruan ESS v1.2.0: Kalibrasi empiris sensor MQ-7/MQ-2, layout responsif, dan optimasi performa.")
    force_update: bool = Field(default=False, description="Apakah pengguna diwajibkan update sebelum memakai aplikasi")
    timestamp: str

@router.get("/health", response_model=HealthResponse, tags=["System"])
async def health_check():
    return HealthResponse(
        status="healthy",
        app=settings.PROJECT_NAME,
        version="2.0.0",
        timestamp=datetime.now(timezone.utc).isoformat()
    )

@router.get("/api/app/version", response_model=AppVersionResponse, tags=["System"])
async def get_app_version():
    """Mengembalikan informasi versi aplikasi Flutter terbaru untuk mekanisme OTA Update (DEVOPS-03)."""
    return AppVersionResponse(
        latest_version=settings.APP_LATEST_VERSION,
        min_required_version=settings.APP_MIN_REQUIRED_VERSION,
        download_url=settings.APP_DOWNLOAD_URL,
        release_notes=settings.APP_RELEASE_NOTES,
        force_update=settings.APP_FORCE_UPDATE,
        timestamp=datetime.now(timezone.utc).isoformat()
    )

@router.get("/api/telemetry/latest", tags=["Telemetry"])
async def get_latest_telemetry(device_id: str = settings.DEFAULT_NODE_ID):
    """Mengambil data telemetri terkini dari Hot Buffer Firebase RTDB untuk gauge real-time Flutter."""
    res_str = get_telemetry(device_id=device_id)
    return json.loads(res_str)

@router.get("/api/logs", tags=["Analytics"])
async def get_historical_logs(
    device_id: str = settings.DEFAULT_NODE_ID,
    limit: int = 30,
    hour_wib: Optional[int] = None
):
    """Mengambil data agregasi menit lampau dari Warm Storage Supabase PostgreSQL untuk grafik analitik Flutter."""
    tz_wib = timezone(timedelta(hours=settings.TIMEZONE_OFFSET_HOURS))
    now_wib = datetime.now(tz_wib)
    utc_start, utc_end = None, None

    if hour_wib is not None:
        h = int(hour_wib)
        target_start = now_wib.replace(hour=h, minute=0, second=0, microsecond=0)
        target_end = now_wib.replace(hour=h, minute=59, second=59, microsecond=0)
        if target_start > now_wib:
            target_start -= timedelta(days=1)
            target_end -= timedelta(days=1)
        utc_start = target_start.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        utc_end = target_end.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    records = query_logs(device_id=device_id, limit=limit, utc_start=utc_start, utc_end=utc_end)
    return {
        "status": "success",
        "device_id": device_id,
        "count": len(records),
        "data": records,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@router.post(
    "/api/chat",
    response_model=ChatResponse,
    tags=["ESI Assistant"],
    dependencies=[Depends(chat_rate_limiter)]
)
async def chat_endpoint(request: ChatRequest):
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Pesan tidak boleh kosong.")
    
    result = ask_esi(request.message, request.history, active_node_id=request.active_node_id)
    return ChatResponse(
        reply=result["reply"],
        status=result["status"],
        timestamp=datetime.now(timezone.utc).isoformat()
    )

@router.post("/api/etl/trigger", tags=["System"])
async def trigger_etl(x_ess_admin_key: Optional[str] = Header(None, alias="X-ESS-Admin-Key")):
    """Memicu siklus ETL secara manual dengan proteksi API Key (SEC-05)."""
    if not settings.ADMIN_API_KEY or not x_ess_admin_key or x_ess_admin_key != settings.ADMIN_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Akses ditolak: Endpoint admin belum dikonfigurasi di server atau Header 'X-ESS-Admin-Key' tidak valid."
        )
    success = run_etl()
    return {"status": "success" if success else "failed", "timestamp": datetime.now(timezone.utc).isoformat()}

@router.get("/api/devices", tags=["Devices"])
async def get_registered_devices():
    """Mengambil daftar perangkat/node IoT yang terdaftar di Supabase PostgreSQL (ess_devices)."""
    devices = query_devices()
    return {
        "status": "success",
        "count": len(devices),
        "data": devices,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
