"""
FastAPI Backend Application & Central Gateway
Environmental Sensing & K3 Intelligent Monitoring System (POLTEKOM)
"""

import os
from contextlib import asynccontextmanager
from typing import Optional, List
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from apscheduler.schedulers.background import BackgroundScheduler
from dotenv import load_dotenv

# Muat environment variables lokal jika ada file .env
load_dotenv()

# Import modul internal
from etl_worker import run_full_etl
from ai_agent import process_chat_message, get_live_telemetry

# =============================================================================
# BACKGROUND SCHEDULER LIFECYCLE (ETL WORKER TIAP 15 MENIT)
# =============================================================================
scheduler = BackgroundScheduler(daemon=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Jalankan scheduler background
    print("[BACKEND STARTUP] Menginisialisasi APScheduler untuk ETL Worker...")
    # Jalankan ETL sekali saat server baru menyala
    try:
        run_full_etl()
    except Exception as e:
        print(f"[STARTUP ETL WARNING] Gagal eksekusi awal: {e}")

    # Jadwalkan ETL berjalan setiap 15 menit
    scheduler.add_job(
        run_full_etl,
        trigger="interval",
        minutes=15,
        id="k3_etl_job",
        replace_existing=True
    )
    scheduler.start()
    print("[BACKEND STARTUP] APScheduler aktif. ETL dijadwalkan setiap 15 menit.")

    yield # Server melayani request

    # Shutdown
    print("[BACKEND SHUTDOWN] Menghentikan scheduler...")
    scheduler.shutdown(wait=False)

# =============================================================================
# INISIALISASI FASTAPI & CORS
# =============================================================================
app = FastAPI(
    title="K3 Environmental Sensing API",
    description="Backend API Gateway & AI Assistant untuk Monitoring K3 Bengkel Mekatronika POLTEKOM",
    version="1.0.0",
    lifespan=lifespan
)

# Izinkan akses dari Flutter Web (Firebase Hosting) dan Android App
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =============================================================================
# DATA SCHEMAS (PYDANTIC)
# =============================================================================
class ChatRequest(BaseModel):
    message: str
    device_id: Optional[str] = "NODE-MRS01"

class ChatResponse(BaseModel):
    reply: str
    status: str

# =============================================================================
# API ENDPOINTS
# =============================================================================

@app.get("/")
def read_root():
    return {
        "system": "Environmental Sensing & K3 Intelligent Monitoring API",
        "institution": "Politeknik Kota Malang (POLTEKOM)",
        "status": "ONLINE",
        "docs_url": "/docs"
    }

@app.get("/health")
def health_check():
    """Endpoint untuk pengecekan status server dan ping uptime"""
    return {
        "status": "healthy",
        "scheduler_running": scheduler.running,
        "database_backend": "Supabase PostgreSQL + Firebase RTDB",
        "ai_engine": "Google Gemini 1.5 Flash"
    }

@app.get("/api/telemetry/live")
def live_telemetry(device_id: str = "NODE-MRS01"):
    """Mengambil telemetri real-time terbaru langsung dari buffer RTDB"""
    result_str = get_live_telemetry(device_id)
    return {"data": result_str}

@app.post("/api/chat", response_model=ChatResponse)
def chat_with_ai(request: ChatRequest):
    """
    Endpoint interaksi AI Chatbot K3 untuk Flutter Frontend.
    Gemini akan secara otomatis memanggil Tool Calling jika membutuhkan data sensor.
    """
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Pesan tidak boleh kosong.")

    result = process_chat_message(request.message)
    return ChatResponse(
        reply=result["reply"],
        status=result.get("status", "success")
    )

@app.post("/api/etl/trigger")
def trigger_manual_etl():
    """Trigger manual untuk menjalankan proses ETL (Extract -> Transform -> Load -> Prune)"""
    try:
        run_full_etl()
        return {"status": "success", "message": "Proses ETL berhasil dipicu secara manual."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal menjalankan ETL: {str(e)}")

# =============================================================================
# ENTRYPOINT LOKAL
# =============================================================================
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
