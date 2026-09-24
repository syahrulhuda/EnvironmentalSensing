# 🍓 Panduan Deployment Raspberry Pi 3B (ESS Backend)

Panduan deployment mandiri (On-Premise) untuk menjalankan backend FastAPI dan AI Agent ESI 24/7 di Raspberry Pi 3B tanpa perlu langganan cloud berbayar.

---

### 1. Persiapan Raspberry Pi 3B
* **OS Rekomendasi:** Raspberry Pi OS Lite (64-bit) terinstall di MicroSD 32 GB.
* Terhubung ke Wi-Fi atau kabel LAN yang stabil.

---

### 2. Instalasi 1-Klik
Buka terminal terminal SSH di Raspberry Pi, lalu jalankan:

```bash
# Clone repositori
git clone https://github.com/syahrulhuda/EnvironmentalSensing.git
cd EnvironmentalSensing/backend

# Jalankan script instalasi otomatis
chmod +x deploy/setup_raspi.sh
./deploy/setup_raspi.sh
```

Isi file `.env` dengan kredensial:
```bash
nano .env
```
Lalu restart service:
```bash
sudo systemctl restart ess-backend.service
```

---

### 3. Monitoring Service di Raspi
* Cek status service:
  ```bash
  sudo systemctl status ess-backend.service
  ```
* Lihat log real-time:
  ```bash
  journalctl -u ess-backend.service -f
  ```

---

### 4. Ekspos ke Internet via Cloudflare Tunnel (Akses untuk Flutter Zaki)
Agar aplikasi Flutter dapat mengakses backend dari luar jaringan Wi-Fi lokal tanpa buka port router:

1. Unduh `cloudflared` ARM di Raspi:
   ```bash
   curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb
   sudo dpkg -i cloudflared.deb
   ```
2. Jalankan quick tunnel gratis:
   ```bash
   cloudflared tunnel --url http://localhost:8000
   ```
   Salin URL HTTPS yang dihasilkan (misal: `https://k3-example.trycloudflare.com`) dan berikan ke Zaki untuk dihubungkan ke aplikasi Flutter.
