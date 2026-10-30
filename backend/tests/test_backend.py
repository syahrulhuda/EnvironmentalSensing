"""
Unit Test Suite for Environmental Sensing System (ESS) Backend Gateway.
Executed in GitHub Actions CI (Stage 1) before deploying to Raspberry Pi.
"""
import os
try:
    import pytest
except ImportError:
    pytest = None

from pydantic import ValidationError

# Set CI environment flag for fail-fast sandbox verification
os.environ["CI"] = "true"
os.environ["ESS_TEST_MODE"] = "true"

from app.core.config import settings
from app.api.routes import ChatMessage, ChatRequest, HealthResponse, AppVersionResponse
from app.core.rate_limiter import InMemoryRateLimiter

def test_settings_initialization():
    """Memverifikasi bahwa konfigurasi backend dapat diinisialisasi dalam mode CI/sandbox."""
    assert settings.PROJECT_NAME == "Environmental Sensing System"
    assert settings.APP_CODE == "ESS"
    assert settings.AGENT_NAME == "ESI"
    assert settings.FIREBASE_RTDB_URL.endswith(".json")

def test_pydantic_chat_models():
    """Memverifikasi validasi schema pesan & permintaan AI."""
    # Valid User Message
    msg = ChatMessage(role="user", content="Cek kondisi gas dan suhu lab.")
    assert msg.role == "user"
    assert "gas" in msg.content

    # Valid Chat Request with history
    req = ChatRequest(message="Apakah kondisi aman?", history=[msg])
    assert req.message == "Apakah kondisi aman?"
    assert len(req.history) == 1

    # Invalid payload (missing required field)
    has_error = False
    try:
        ChatMessage(role="user")  # missing content
    except ValidationError:
        has_error = True
    assert has_error, "ChatMessage without content must raise ValidationError"

def test_health_response_schema():
    """Memverifikasi schema respons endpoint healthcheck."""
    res = HealthResponse(
        status="healthy",
        app=settings.PROJECT_NAME,
        version="2.0.0",
        timestamp="2026-10-30T00:00:00Z"
    )
    assert res.status == "healthy"
    assert res.version == "2.0.0"

def test_app_version_schema():
    """Memverifikasi schema respons endpoint versi aplikasi mobile (DEVOPS-03)."""
    ver = AppVersionResponse(
        latest_version="1.2.0",
        min_required_version="1.0.0",
        download_url="https://example.com/app.apk",
        release_notes="Catatan rilis",
        force_update=False,
        timestamp="2026-10-30T00:00:00Z"
    )
    assert ver.latest_version == "1.2.0"
    assert ver.min_required_version == "1.0.0"
    assert ver.force_update is False

    # Invalid payload (missing required fields)
    has_error = False
    try:
        AppVersionResponse(latest_version="1.2.0")
    except ValidationError:
        has_error = True
    assert has_error, "AppVersionResponse without required fields must raise ValidationError"

def test_in_memory_rate_limiter():
    """Memverifikasi rate limiter sliding-window memblokir request saat melebihi batas."""
    from fastapi import HTTPException

    limiter = InMemoryRateLimiter(requests_limit=2, window_seconds=10)

    # Mock ASGI Request object
    class MockRequest:
        def __init__(self, ip="192.168.1.50"):
            self.headers = {"x-forwarded-for": ip}
            self.client = None

    mock_req = MockRequest()

    # Request 1 & 2 harus lolos tanpa exception
    limiter.check(mock_req)
    limiter.check(mock_req)

    # Request 3 harus memicu HTTP 429 Too Many Requests
    rate_limited = False
    try:
        limiter.check(mock_req)
    except HTTPException as exc:
        rate_limited = True
        assert exc.status_code == 429
        assert "Batas laju permintaan" in exc.detail
    assert rate_limited, "Third request must raise HTTP 429 HTTPException"

def test_fastapi_health_endpoint():
    """Memverifikasi bahwa rute /health dapat dijangkau dan mengembalikan status 200."""
    try:
        from fastapi.testclient import TestClient
        from main import app

        client = TestClient(app)
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["version"] == "2.0.0"
    except (ImportError, RuntimeError):
        # Jika httpx belum terpasang di environment lokal, lewati testclient
        if pytest:
            pytest.skip("TestClient requires httpx (installed in CI runner)")

def test_fastapi_app_version_endpoint():
    """Memverifikasi bahwa rute /api/app/version mengembalikan status 200 dan payload valid (DEVOPS-03)."""
    try:
        from fastapi.testclient import TestClient
        from main import app

        client = TestClient(app)
        response = client.get("/api/app/version")
        assert response.status_code == 200
        data = response.json()
        assert "latest_version" in data
        assert "min_required_version" in data
        assert "download_url" in data
        assert "release_notes" in data
        assert "force_update" in data
        assert data["latest_version"] == settings.APP_LATEST_VERSION
    except (ImportError, RuntimeError):
        if pytest:
            pytest.skip("TestClient requires httpx (installed in CI runner)")

