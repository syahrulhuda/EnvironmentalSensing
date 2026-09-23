# 🏭 Environmental Sensing & K3 Intelligent Monitoring System
> **Sistem Monitoring K3 & Deteksi Gas Beracun Cerdas Berbasis IoT, Tiered Cloud Storage, dan AI Assistant**  
> *Lokasi Penelitian: Laboratorium & Bengkel Teknik Mekatronika, Politeknik Kota Malang (POLTEKOM)*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: ESP32](https://img.shields.io/badge/Hardware-ESP32--WROOM%20%7C%20C3-red.svg)](https://espressif.com/)
[![Database: Firebase RTDB + Supabase](https://img.shields.io/badge/Database-RTDB%20%2B%20PostgreSQL-orange.svg)](https://supabase.com/)
[![AI: Google Gemini Flash](https://img.shields.io/badge/AI-Gemini%20Flash%20Agent-purple.svg)](https://aistudio.google.com/)
[![Frontend: Flutter Multiplatform](https://img.shields.io/badge/Frontend-Flutter%20Web%20%26%20Mobile-02569B.svg)](https://flutter.dev/)

---

## 📌 Ringkasan Eksekutif (Executive Summary)

Dalam aktivitas praktikum bengkel mekatronika (khususnya proses pengelasan /*welding* dan pematerian /*soldering*), gas beracun Karbon Monoksida (**CO**) dan asap pekat kerap terakumulasi tanpa disadari oleh teknisi. Paparan gas CO di atas ambang batas K3 (**50 PPM**) dapat menyebabkan pusing, keracunan fatal, hingga penurunan performa kerja.

Sistem **Environmental Sensing** ini dikembangkan untuk menjawab tantangan tersebut melalui arsitektur multi-layer modern:
1. **Edge Node (ESP32)** mengakuisisi kadar gas CO (MQ-7), asap (MQ-2), serta suhu dan kelembapan (DHT22) dengan transmisi HTTPS non-blocking.
2. **Tiered Cloud Storage** menggabungkan **Firebase RTDB** sebagai *Hot Buffer* (sliding window 2 jam terakhir) dan **Supabase PostgreSQL** sebagai *Warm Storage* permanen (agregasi 1-menitan berindeks).
3. **AI Brain (Google Gemini)** di backend FastAPI bertindak sebagai asisten K3 cerdas yang mampu menganalisis kondisi udara detik ini sekaligus riwayat mingguan menggunakan metode *Tool Calling (ReAct)*.
4. **Multiplatform Client (Flutter)** menyajikan dashboard visual real-time dan antarmuka percakapan interaktif baik di peramban Web maupun aplikasi Android.

---

## 🏗️ Arsitektur Sistem 5-Layer (System Architecture)

```
[Layer 5: Presentation Tier]
     Aplikasi Flutter Multiplatform (Web & Android)
     • Dashboard Real-time (Gauges, Visual Alert K3)
     • Asisten Chatbot K3 Interaktif
            ▲
            │ (REST HTTPS: POST /api/chat)
            ▼
[Layer 4: Intelligence & API Gateway Tier]
     FastAPI Backend Container (Hugging Face Spaces)
     • Google Gemini Flash ReAct Agent (Tool Calling)
     • Proteksi Kredensial & Secrets Management
            ▲
            │ (Kueri Status & Tren K3)
            ▼
[Layer 3: Processing & Analytical Tier]
     Background Worker ETL (APScheduler Tiap 15 Menit)
     • Pembersihan data & Agregasi 1-menitan
     • Penyimpanan Permanen: Supabase PostgreSQL (Tabel workshop_k3_logs)
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
     ESP32 DevKit V1 (WROOM-32 / ESP32-C3)
     • Sensor Gas Karbon Monoksida (MQ-7)
     • Sensor Gas & Asap (MQ-2)
     • Sensor Suhu & Kelembapan (DHT22)
     • Indikator Visual LED RGB K3
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
├── hardware/              # Layer 1: Edge Sensing Node (ESP32)
│   ├── src/               # Kode sumber C++ (PlatformIO / Arduino)
│   ├── platformio.ini     # Konfigurasi build PlatformIO
│   └── diagram.json       # Simulasi rangkaian Wokwi
│
├── backend/               # Layer 3 & 4: FastAPI, ETL Worker & AI Gemini
│   ├── main.py            # API Server & background scheduler
│   ├── ai_agent.py        # Gemini ReAct Tool Calling Agent
│   ├── etl_worker.py      # Worker sinkronisasi RTDB -> Supabase
│   ├── Dockerfile         # Konfigurasi container deploy Hugging Face
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
git clone https://github.com/username/environmentalsensing.git
cd environmentalsensing
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

### Menjalankan Firmware Hardware:
Buka folder `hardware/` menggunakan VS Code dengan ekstensi **PlatformIO**, lalu klik **Upload** ke board ESP32 kamu.

---

## 📄 Lisensi & Hak Cipta
Dikembangkan untuk Laporan Praktik Kerja Lapangan / Magang Industri & Penelitian Akademik  
**Jurusan Teknik Mekatronika, Politeknik Kota Malang (POLTEKOM)**  
Peneliti Utama: **Syahrul Huda**
