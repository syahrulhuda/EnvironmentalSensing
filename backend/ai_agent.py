"""Backward-compatible shim for ai_agent. Use app.services.ai_service and app.tools instead."""
from app.services.ai_service import ask_esi
from app.tools import get_telemetry, get_history, get_sop

def process_chat_message(user_message: str, history: list = None) -> dict:
    return ask_esi(user_message, history)

get_live_telemetry = get_telemetry
get_historical_k3_stats = get_history
get_k3_safety_sop = get_sop
