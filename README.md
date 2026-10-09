# 🏭 Smart Environmental Sensing System (ESS)
> **Sistem Monitoring Kualitas Udara & Deteksi Gas Berbahaya Berbasis IoT, Tiered Cloud Storage, dan ESI AI Assistant**  
> *Lokasi Penelitian: Laboratorium & Bengkel Teknik Mekatronika, Politeknik Kota Malang (POLTEKOM)*

[![Platform: ESP32](https://img.shields.io/badge/Hardware-ESP32--WROOM%20%7C%20C3-red.svg)](https://espressif.com/)
[![Database: Firebase RTDB + Supabase](https://img.shields.io/badge/Database-RTDB%20%2B%20PostgreSQL-orange.svg)](https://supabase.com/)
[![AI: ESI Agent](https://img.shields.io/badge/AI-ESI%20(Gemini%20Flash)--Lite-purple.svg)](https://aistudio.google.com/)
[![Frontend: Flutter Multiplatform](https://img.shields.io/badge/Frontend-Flutter%20Web%20%26%20Mobile-02569B.svg)](https://flutter.dev/)

---

## 📌 Ringkasan Eksekutif (Executive Summary)

Dalam aktivitas praktikum bengkel mekatronika (khususnya proses pengelasan /*welding* dan pematerian /*soldering*), gas beracun Karbon Monoksida (**CO**) dan asap pekat kerap terakumulasi tanpa disadari oleh teknisi. Paparan gas CO di atas ambang batas keselamatan ESS (**50 PPM**) dapat menyebabkan pusing, keracunan fatal, hingga penurunan performa kerja.

Sistem **Smart Environmental Sensing System (ESS)** ini dikembangkan untuk menjawab tantangan tersebut melalui arsitektur multi-layer modern:
1. **Edge Node (ESP32)** mengakuisisi kadar gas CO (MQ-7), asap (MQ-2), serta suhu dan kelembapan (DHT22) dengan transmisi HTTPS non-blocking.
2. **Tiered Cloud Storage** menggabungkan **Firebase RTDB** sebagai *Hot Buffer* (sliding window 2 jam terakhir) dan **Supabase PostgreSQL** sebagai *Warm Storage* permanen (agregasi 1-menitan berindeks).
3. **AI Brain (ESI via Google Gemini)** di backend FastAPI bertindak sebagai asisten cerdas yang mampu menganalisis kondisi udara detik ini sekaligus riwayat mingguan menggunakan metode *Tool Calling (ReAct)*.
4. **Multiplatform Client (Flutter)** menyajikan dashboard visual real-time dan antarmuka percakapan interaktif baik di peramban Web maupun aplikasi Android.

---

## 🏗️ Arsitektur Sistem 5-Layer (System Architecture)

```
[Layer 5: Presentation Tier]
     Aplikasi Flutter Multiplatform (Web & Android)
     • ESS Dashboard (Gauges, Visual Alert Status)
     • Chat with ESI (AI Assistant)
            ▲
            │ (REST HTTPS: POST /api/chat)
            ▼
[Layer 4: Intelligence & API Gateway Tier]
     FastAPI Backend (Local / Raspberry Pi 3B / Cloud)
     • ESI Agent (Gemini Flash-Lite ReAct Tool Calling)
     • Proteksi Kredensial & Secrets Management
            ▲
            │ (Kueri Telemetri & Tren ESS)
            ▼
[Layer 3: Processing & Analytical Tier]
     Background Worker ETL (APScheduler Tiap 15 Menit)
     • Pembersihan data & Agregasi 1-menitan
     • Penyimpanan Permanen: Supabase PostgreSQL (Tabel ess_logs & ess_anomalies)
            ▲
            │ (Ekstrak Buffer & Pruning > 2 Jam)
            ▼
[Layer 2: Transport & Ingestion Tier]
     Firebase Realtime Database (Singapura)
     • Hot Buffer: /telemetry/buffer (FIFO Sliding Window 2 Jam)
            ▲
            │ (HTTPS POST Telemetri Tiap 3 Detik)
            ▼
[Layer 1: Perception & Edge Sensing Tier]
     ESP32-C3 SuperMini (RISC-V 32-bit Single-Core, 16-pin)
     • Display OLED 0.96" I2C SSD1306 (SDA: GPIO 8, SCL: GPIO 9)
     • Sensor Gas Karbon Monoksida (MQ-7 • GPIO 1 • Baseline 1.25V / 1550 ADC)
     • Sensor Asap & Gas Mudah Terbakar (MQ-2 • GPIO 0 • Baseline 0.37V / 460 ADC)
     • Sensor Suhu & Kelembapan (DHT22 • GPIO 10 • Kompensasi Panas Koil MQ)
     • Indikator Visual K3: LED RGB Common Cathode (GPIO 4: R, GPIO 3: G, GPIO 2: B)
     • Driver Kipas PWM: Transistor SS8050 NPN + Diode Flyback 1N4007 (GPIO 5)
     • Filter Proteksi Daya: Elco 100 µF (C1) + Keramik 100 nF (C2) + Terminal KF301
```

---

## 📁 Struktur Monorepo

```text
environmentalsensing/
├── .gitignore             # Proteksi secrets (.env, keys, build artifacts)
├── README.md              # Wajah proyek & panduan utama
├── RULEBOOK.md            # Konstitusi proyek & standar penulisan kode
├── WHITEBOARD.md          # Dapur kotor, grand plan, & log ide
│
├── schematics/            # Desain PCB & Hardware BOM
│   ├── COMPONENTS.md      # Bill of Materials & panduan perakitan fisik
│   ├── PCB_PCB_ESS_5_*.json # Layout PCB EasyEDA Single-Layer 70x40 mm
│   └── SCH_ESS_*.json     # Skematik rangkaian resmi
│
├── hardware/              # Layer 1: Edge Sensing Node (ESP32)
│   ├── src/               # Kode sumber produksi C++ (PlatformIO / Arduino)
│   │   ├── main.cpp       # Firmware produksi (OLED SSD1306 + RTDB Streaming)
│   │   └── secrets.example.h # Template kredensial Wi-Fi & Firebase
│   ├── test_bench/        # Skrip uji bangku perangkat keras
│   │   ├── tes_c3/        # Test bench offline mandiri ESP32-C3 SuperMini
│   │   └── tes_wroom/     # Test bench ESP32 WROOM-32 legacy
│   └── platformio.ini     # Konfigurasi build PlatformIO (Adafruit SSD1306)
│
├── backend/               # Layer 3 & 4: FastAPI, ETL Worker & AI ESI
│   ├── app/               # Modul Python Terstruktur
│   │   ├── core/          # Konfigurasi terpusat & client database
│   │   ├── data/          # Basis pengetahuan SOP keselamatan
│   │   ├── tools/         # ReAct tools (telemetry, analytics, sop)
│   │   ├── services/      # Pipeline ETL & ESI Reasoning engine
│   │   └── api/           # Endpoint router (/api/chat, /health)
│   ├── deploy/            # Konfigurasi deployment Raspberry Pi 3B (systemd & setup script)
│   ├── main.py            # Server entrypoint sangat ringkas (< 40 baris)
│   ├── chat_cli.py        # Terminal interactive client
│   ├── requirements.txt   # Dependensi Python
│   └── .env.example       # Template variabel lingkungan
│
└── frontend/              # Layer 5: Client App (Flutter Web & Mobile)
    ├── lib/               # Kode sumber Dart (UI & state management)
    ├── pubspec.yaml       # Dependensi Flutter
    └── web/               # Konfigurasi deploy ke Firebase Hosting
```

---

## 🛠️ Panduan Git & Kontribusi

### 1. Kloning Repositori
```bash
git clone https://github.com/syahrulhuda/EnvironmentalSensing.git
cd EnvironmentalSensing
```

### 2. Standar Commit (Conventional Commits)
Sesuai dengan `RULEBOOK.md`, setiap commit wajib mengikuti format:
- `feat:` Fitur baru pada hardware, backend, atau frontend.
- `fix:` Perbaikan bug / kalibrasi sensor.
- `docs:` Pembaruan dokumentasi.
- `refactor:` Restrukturisasi kode tanpa mengubah fungsionalitas.

---

## 🚀 Panduan Memulai Cepat (Quickstart)

### Menjalankan Backend Lokal:
```bash
cd backend
cp .env.example .env     # Isi kredensial API kamu
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Menjalankan & Mem-flash Firmware Hardware:

#### Opsi A: PlatformIO IDE (VS Code)
Buka folder `hardware/` menggunakan VS Code dengan ekstensi **PlatformIO**, sambungkan board ke port USB-C, lalu klik **Upload**.

#### Opsi B: Arduino IDE (Pengujian Offline Test Bench)
1. Buka berkas `hardware/test_bench/tes_c3/tes_c3.ino`.
2. Pasang board support `esp32` by Espressif Systems (v2.0.x / v3.x).
3. Atur menu **Tools**:
   * **Board:** `ESP32C3 Dev Module`
   * **Flash Mode:** **`DIO`** *(Wajib DIO, jangan gunakan QIO karena menyebabkan crash bootloader)*
   * **USB CDC On Boot:** **`Enabled`** *(Wajib Enabled agar Serial Monitor terbaca via USB-C internal)*
   * **Port:** Pilih COM yang terdeteksi (misal `COM8`).
4. **Troubleshooting USB Flapping / Putus-Nyambung:**
   * Jika saat pertama kali dicolok perangkat berbunyi putus-nyambung: **Tahan tombol BOOT, tekan tombol RST sekali, lalu lepas tombol BOOT**.
   * Board akan terkunci di mode download bootloader dan port COM akan terdeteksi stabil di Device Manager.
5. Klik tombol **Upload**, lalu buka **Serial Monitor** pada baudrate `115200`.
