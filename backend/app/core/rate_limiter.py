import time
from collections import defaultdict, deque
from threading import Lock
from typing import Optional
from fastapi import Request, HTTPException, status
from app.core.config import settings

class InMemoryRateLimiter:
    """
    Sliding-window in-memory rate limiter untuk membatasi kuota request AI Agent (TD-B05).
    Thread-safe untuk multi-worker / multi-threading ASGI server.
    """
    def __init__(self, requests_limit: int = 15, window_seconds: int = 60):
        self.requests_limit = requests_limit
        self.window_seconds = window_seconds
        self._history = defaultdict(deque)
        self._lock = Lock()

    def _get_client_id(self, request: Request) -> str:
        # Baca header proxy (Ngrok / Cloudflare Tunnel) atau fallback ke IP socket
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        if request.client and request.client.host:
            return request.client.host
        return "unknown"

    def check(self, request: Request):
        client_id = self._get_client_id(request)
        now = time.time()
        cutoff = now - self.window_seconds

        with self._lock:
            # Housekeeping berkala jika map IP membengkak (mencegah memory leak di Raspi)
            if len(self._history) > 1000:
                expired = [k for k, q in self._history.items() if not q or q[-1] < cutoff]
                for k in expired:
                    del self._history[k]

            queue = self._history[client_id]
            while queue and queue[0] < cutoff:
                queue.popleft()

            if len(queue) >= self.requests_limit:
                retry_after = int(self.window_seconds - (now - queue[0])) + 1
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=(
                        f"Batas laju permintaan AI terlampaui. "
                        f"Maksimal {self.requests_limit} pesan per {self.window_seconds} detik. "
                        f"Silakan coba kembali dalam {max(1, retry_after)} detik."
                    ),
                    headers={"Retry-After": str(max(1, retry_after))}
                )

            queue.append(now)

    def __call__(self, request: Request):
        """FastAPI Dependency callable."""
        self.check(request)

# Limiter tunggal untuk endpoint POST /api/chat
chat_rate_limiter = InMemoryRateLimiter(
    requests_limit=settings.CHAT_RATE_LIMIT_PER_MINUTE,
    window_seconds=60
)
