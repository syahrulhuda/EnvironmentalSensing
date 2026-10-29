import json
import urllib.request
import urllib.error
import urllib.parse
from typing import Optional, List, Dict, Any
from app.core.config import settings

def fetch_rtdb() -> Optional[Dict[str, Any]]:
    req = urllib.request.Request(settings.get_rtdb_url(), headers={"User-Agent": "ESS-Backend"})
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
        settings.get_rtdb_url(),
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

def upsert_logs(records: List[Dict[str, Any]]) -> Optional[List[Dict[str, Any]]]:
    if not records:
        return None
    endpoint = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_LOGS}?on_conflict=device_id,recorded_at"
    headers = {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=representation"
    }
    req = urllib.request.Request(endpoint, data=json.dumps(records).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            if res.status in (200, 201):
                return json.loads(res.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"[ESS DB] Supabase Upsert HTTP {e.code}: {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"[ESS DB] Supabase Upsert error: {e}")
    return None

def upsert_anomaly(anomaly: Dict[str, Any]) -> bool:
    if not anomaly:
        return False
    endpoint = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_ANOMALIES}?on_conflict=id"
    headers = {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    req = urllib.request.Request(endpoint, data=json.dumps(anomaly).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            return res.status in (200, 201)
    except Exception as e:
        print(f"[ESS DB] Supabase Anomaly Upsert error: {e}")
        return False

def query_active_anomaly() -> Optional[Dict[str, Any]]:
    endpoint = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_ANOMALIES}?end_log_id=is.null&order=id.desc&limit=1"
    headers = {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json"
    }
    req = urllib.request.Request(endpoint, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            if res.status in (200, 206):
                rows = json.loads(res.read().decode("utf-8"))
                return rows[0] if rows else None
    except Exception as e:
        print(f"[ESS DB] Error checking active anomaly: {e}")
    return None

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

def insert_anomalies(records: List[Dict[str, Any]]) -> bool:
    if not records:
        return False
    endpoint = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_ANOMALIES}"
    headers = {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json"
    }
    req = urllib.request.Request(endpoint, data=json.dumps(records).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            return res.status in (200, 201)
    except urllib.error.HTTPError as e:
        print(f"[ESS DB] Supabase Anomaly Insert HTTP {e.code}: {e.read().decode('utf-8')}")
        return False
    except Exception as e:
        print(f"[ESS DB] Supabase Anomaly Insert error: {e}")
        return False

def query_existing_anomaly_timestamps(device_id: str, timestamps: List[str]) -> set:
    if not timestamps:
        return set()
    min_ts = urllib.parse.quote(min(timestamps))
    max_ts = urllib.parse.quote(max(timestamps))
    endpoint = (
        f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_ANOMALIES}"
        f"?device_id=eq.{device_id}&triggered_at=gte.{min_ts}&triggered_at=lte.{max_ts}&select=triggered_at"
    )
    headers = {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json"
    }
    req = urllib.request.Request(endpoint, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            if res.status in (200, 206):
                rows = json.loads(res.read().decode("utf-8"))
                return {r["triggered_at"] for r in rows if "triggered_at" in r}
    except Exception as e:
        print(f"[ESS DB] Error checking existing anomalies: {e}")
    return set()

def query_anomalies(device_id: str = settings.DEFAULT_NODE_ID, limit: int = 50) -> List[Dict[str, Any]]:
    endpoint = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_ANOMALIES}?device_id=eq.{device_id}&order=triggered_at.desc&limit={limit}"
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
        print(f"[ESS DB] Supabase Anomaly Query error: {e}")
    return []

def query_devices() -> List[Dict[str, Any]]:
    """Mengambil daftar node/perangkat yang terdaftar di Supabase PostgreSQL beserta relasi zonanya."""
    endpoint = f"{settings.SUPABASE_URL}/rest/v1/{settings.TABLE_DEVICES}?select=*,ess_zones(*)&order=created_at.asc"
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
        print(f"[ESS DB] Supabase Devices Query error: {e}")
    return []

