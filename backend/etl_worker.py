"""Backward-compatible shim for etl_worker. Use app.services.etl_service instead."""
from app.services.etl_service import run_etl, aggregate_telemetry, prune_buffer

def run_full_etl():
    return run_etl()

if __name__ == "__main__":
    run_etl()
