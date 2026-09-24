import json
import urllib.request
import urllib.error
from typing import Optional, List, Dict, Any
from app.core.config import settings

def fetch_rtdb() -> Optional[Dict[str, Any]]:
    req = urllib.request.Request(settings.FIREBASE_RTDB_URL, headers={"User-Agent": "ESS-Backend"})
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            if res.status == 200:
                data = json.loads(res.read().decode("utf-8"))
                return data if data else {}
    except Exception as e:
        print(f"[ESS DB] Error fetching RTDB: {e}")
    return None

def patch_rtdb(payload: Dict[str, Any]) -> bool:
    data_bytes = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        settings.FIREBASE_RTDB_URL,
        data=data_bytes,
        headers={"Content-Type": "application/json", "X-HTTP-Method-Override": "PATCH"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            return res.status == 200
    except Exception as e:
        print(f"[ESS DB] Error patching RTDB: {e}")
        return False

def upsert_logs(records: List[Dict[str, Any]]) -> bool:
    if not records:
        return False
    endpoint = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_LOGS}?on_conflict=device_id,recorded_at"
    headers = {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    req = urllib.request.Request(endpoint, data=json.dumps(records).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            return res.status in (200, 201)
    except urllib.error.HTTPError as e:
        print(f"[ESS DB] Supabase Upsert HTTP {e.code}: {e.read().decode('utf-8')}")
        return False
    except Exception as e:
        print(f"[ESS DB] Supabase Upsert error: {e}")
        return False

def query_logs(
    device_id: str = settings.DEFAULT_NODE_ID,
    limit: int = 30,
    utc_start: Optional[str] = None,
    utc_end: Optional[str] = None
) -> List[Dict[str, Any]]:
    base = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_LOGS}?device_id=eq.{device_id}"
    if utc_start and utc_end:
        endpoint = f"{base}&recorded_at=gte.{utc_start}&recorded_at=lte.{utc_end}&order=recorded_at.asc&limit={limit}"
    else:
        endpoint = f"{base}&order=recorded_at.desc&limit={limit}"

    headers = {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json"
    }
    req = urllib.request.Request(endpoint, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            if res.status in (200, 206):
                return json.loads(res.read().decode("utf-8"))
    except Exception as e:
        print(f"[ESS DB] Supabase Query error: {e}")
    return []
