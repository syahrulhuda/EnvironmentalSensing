#!/bin/bash
# =============================================================================
# Environmental Sensing System (ESS) - Raspberry Pi 3B Setup Script
# =============================================================================
set -e

echo "=========================================================="
echo "🍓 Memulai Setup Backend ESS di Raspberry Pi 3B..."
echo "=========================================================="

# 1. Update paket sistem
sudo apt update && sudo apt install -y python3 python3-pip python3-venv curl

# 2. Setup virtual environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
cd "$BACKEND_DIR"

if [ ! -d "venv" ]; then
    echo "📦 Membuat virtual environment Python..."
    python3 -m venv venv
fi

echo "📦 Menginstall dependensi requirements.txt..."
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

# 3. Validasi file .env
if [ ! -f ".env" ]; then
    echo "⚠️ File .env belum ditemukan! Menyalin dari .env.example..."
    cp .env.example .env
    echo "👉 Silakan edit file .env dengan kredensial asli Anda: nano .env"
fi

# 4. Registrasi systemd service
echo "⚙️ Mendaftarkan systemd service (auto-start on boot)..."
sudo cp "$SCRIPT_DIR/ess-backend.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ess-backend.service
sudo systemctl restart ess-backend.service

echo "=========================================================="
echo "✅ Setup Selesai! Backend ESS aktif di port 8000."
echo "Periksa status service: sudo systemctl status ess-backend.service"
echo "Lihat live logs: journalctl -u ess-backend.service -f"
echo "=========================================================="
