from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.background import BackgroundScheduler
import uvicorn

from app.core.config import settings
from app.api.routes import router
from app.services.etl_service import run_etl

scheduler = BackgroundScheduler(daemon=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"[ESS BACKEND] Starting APScheduler (15-min interval)...")
    scheduler.add_job(func=run_etl, trigger="interval", minutes=15, id="ess_etl_job")
    scheduler.start()
    yield
    print("[ESS BACKEND] Shutting down scheduler...")
    scheduler.shutdown(wait=False)

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend Gateway & AI Agent Service for Environmental Sensing System (POLTEKOM)",
    version="2.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)

if __name__ == "__main__":
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
