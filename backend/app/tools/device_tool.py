import json
from app.core.database import query_devices

def get_devices() -> str:
    """
    Mengambil daftar metadata resmi seluruh perangkat/node sensor IoT yang terdaftar di Politeknik Kota Malang dari database.
    Mengembalikan ID node, nama ruangan/area bengkel, lokasi fisik, dan status operasional.
    Gunakan tool ini ketika pengguna menanyakan ada node/sensor apa saja, letak ruangan, atau daftar perangkat yang terpasang.
    """
    devices = query_devices()
    if not devices:
        return json.dumps({
            "status": "empty",
            "message": "Tidak ada data perangkat yang terdaftar di database."
        })
    return json.dumps({
        "status": "success",
        "total_devices": len(devices),
        "devices": devices
    })
