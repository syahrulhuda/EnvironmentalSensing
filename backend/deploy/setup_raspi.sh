#!/bin/bash
# =============================================================================
# Environmental Sensing System (ESS) - Raspberry Pi Setup Script
# =============================================================================
set -e

echo "=========================================================="
echo "🍓 Memulai Setup Backend ESS di Raspberry Pi..."
echo "=========================================================="

CURRENT_USER=$(whoami)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "👤 User aktif: $CURRENT_USER"
echo "📂 Direktori backend: $BACKEND_DIR"

# 1. Update paket sistem dasar
echo "📦 Memeriksa dependensi sistem..."
sudo apt update && sudo apt install -y python3 python3-pip python3-venv curl git

# 2. Setup virtual environment
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
    echo "👉 PENTING: Silakan isi kredensial asli Anda di: nano $BACKEND_DIR/.env"
fi

# 4. Registrasi systemd service secara dinamis
echo "⚙️ Mendaftarkan systemd service (auto-start on boot)..."
cat <<EOF | sudo tee /etc/systemd/system/ess-backend.service > /dev/null
[Unit]
Description=Environmental Sensing System (ESS) Backend & ESI AI Service
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$BACKEND_DIR
EnvironmentFile=$BACKEND_DIR/.env
Environment=PYTHONUNBUFFERED=1
ExecStart=$BACKEND_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ess-backend.service

echo "=========================================================="
echo "✅ Setup Berhasil!"
echo "Langkah selanjutnya:"
echo "1. Pastikan isi kredensial di file .env:"
echo "   nano $BACKEND_DIR/.env"
echo "2. Jalankan atau restart service backend:"
echo "   sudo systemctl restart ess-backend.service"
echo "3. Cek status service:"
echo "   sudo systemctl status ess-backend.service"
echo "4. Pantau log real-time:"
echo "   journalctl -u ess-backend.service -f"
echo "=========================================================="
