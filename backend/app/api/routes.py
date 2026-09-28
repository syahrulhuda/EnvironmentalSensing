from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.core.config import settings
from app.services.ai_service import ask_esi
from app.services.etl_service import run_etl

router = APIRouter()

class ChatMessage(BaseModel):
    role: str = Field(..., description="Peran pesan: 'user' atau 'model' / 'assistant'", example="user")
    content: str = Field(..., description="Isi teks pesan", example="Bagaimana kondisi gas CO sekarang?")

class ChatRequest(BaseModel):
    message: str = Field(..., example="Bagaimana kualitas udara bengkel saat ini?")
    history: Optional[List[ChatMessage]] = Field(default=None, description="Riwayat obrolan bertingkat")

class ChatResponse(BaseModel):
    reply: str
    status: str
    timestamp: str

class HealthResponse(BaseModel):
    status: str
    app: str
    version: str
    timestamp: str

@router.get("/health", response_model=HealthResponse, tags=["System"])
async def health_check():
    return HealthResponse(
        status="healthy",
        app=settings.PROJECT_NAME,
        version="2.0.0",
        timestamp=datetime.now(timezone.utc).isoformat()
    )

@router.get("/api/telemetry/latest", tags=["Telemetry"])
async def get_latest_telemetry(device_id: str = settings.DEFAULT_NODE_ID):
    """Mengambil data telemetri terkini dari Hot Buffer Firebase RTDB untuk gauge real-time Flutter."""
    import json
    from app.tools.telemetry_tool import get_telemetry
    res_str = get_telemetry(device_id=device_id)
    return json.loads(res_str)

@router.get("/api/logs", tags=["Analytics"])
async def get_historical_logs(
    device_id: str = settings.DEFAULT_NODE_ID,
    limit: int = 30,
    hour_wib: Optional[int] = None
):
    """Mengambil data agregasi menit lampau dari Warm Storage Supabase PostgreSQL untuk grafik analitik Flutter."""
    from datetime import timedelta
    from app.core.database import query_logs

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

@router.post("/api/chat", response_model=ChatResponse, tags=["ESI Assistant"])
async def chat_endpoint(request: ChatRequest):
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Pesan tidak boleh kosong.")
    
    result = ask_esi(request.message, request.history)
    return ChatResponse(
        reply=result["reply"],
        status=result["status"],
        timestamp=datetime.now(timezone.utc).isoformat()
    )

@router.post("/api/etl/trigger", tags=["System"])
async def trigger_etl():
    success = run_etl()
    return {"status": "success" if success else "failed", "timestamp": datetime.now(timezone.utc).isoformat()}
