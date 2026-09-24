from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.core.config import settings
from app.services.ai_service import ask_esi
from app.services.etl_service import run_etl

router = APIRouter()

class ChatRequest(BaseModel):
    message: str = Field(..., example="Bagaimana kualitas udara bengkel saat ini?")
    history: Optional[List[Dict[str, Any]]] = None

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
