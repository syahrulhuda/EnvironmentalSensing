# 📋 WHITEBOARD (The Living Plan & Scratchpad)

Dokumen kerja aktif untuk mencatat fokus berjalan, arsip ide tim, serta evaluasi audit teknis sistem **Smart Environmental Sensing System (ESS)**.

---

# 🎯 Section 1: Current Grand Plan
> [!IMPORTANT]
> **Fokus Utama Saat Ini:** Validasi prototipe breadboard ESP32-C3 SuperMini (OLED SSD1306, DHT22, MQ-7, MQ-2, LED RGB CC, Filter C1/C2) telah tuntas 100%. Fokus transisi berikutnya: pengujian beban inrush kipas DC 4010 + transistor SS8050 saat kipas tiba, persiapan cetak PCB `PCB_ESS_5`, serta integrasi streaming live ke Firebase RTDB buffer.
> **Affected Areas:** `hardware/`, `schematics/`, `deploy/`.
> **Success Criteria:** 
> 1. Verifikasi offline seluruh sensor & display via `tes_c3.ino` (SELESAI - Teruji fisik).
> 2. Proof of concept peredaman noise rangkaian filter C1/C2 (SELESAI - 5.10-5.15V diredam ke 5.13-5.14V).
> 3. Standardisasi kurva & baseline kalibrasi ADC udara bersih MQ-7 (1550) & MQ-2 (460) (SELESAI).
> 4. Kompensasi mikroklimat thermal cross-heating DHT22 via `TEMP_OFFSET` (SELESAI).
> 5. Uji inrush current & PWM kipas 4010 via transistor SS8050 & diode 1N4007 (Menunggu kedatangan kipas).
> 6. Fabrikasi & penyolderan PCB single-layer 70x40 mm `PCB_ESS_5`.

---

# 💡 Section 2: Ideas to Discuss
*Log arsip ide abadi. Jangan menghapus catatan di bagian ini sebagai jejak rekam rekayasa sistem.*

### [Status: DITERIMA] Arsitektur Hybrid Hot-Warm Tiered Storage (RTDB + Supabase)
- **Tanggal & Inisiator:** `[21-09-2026]` - Huda
- **Ide:** Menggabungkan Firebase RTDB sebagai buffer cepat (Hot Storage 2 jam terakhir) dan Supabase PostgreSQL sebagai gudang analitik permanen (Warm Storage).
- **Diskusi:**
  - RTDB gratis memiliki batas 1 GB. Jika menyimpan data per 3 detik selamanya, kuota akan habis dalam beberapa bulan.
  - Dengan membersihkan data lama (> 2 jam) di RTDB dan memadatkannya menjadi agregat 1-menitan di Supabase, kuota RTDB terjaga di bawah 5 MB selamanya, dan Supabase mampu menyimpan data hingga 7 tahun.
- **Keputusan:** `[21-09-2026]` - **[DITERIMA]** Berhasil diuji coba secara fisik dengan 1.661 data mentah terkonversi menjadi 84 baris di PostgreSQL.

### [Status: DITERIMA] FIFO Continuous Sliding Window 2 Jam di RTDB
- **Tanggal & Inisiator:** `[22-09-2026]` - Huda
- **Ide:** Mekanisme pemangkasan (*pruning*) RTDB tidak boleh menghapus seluruh data secara berkala (*flush & refill*), melainkan mempertahankan rentang waktu bergerak 2 jam terakhir (`now - 2 hours`) secara kontinu.
- **Diskusi:**
  - Jika data dihapus total, pengguna yang mengakses chatbot sesaat setelah pembersihan akan kehilangan konteks data.
  - Dengan menghapus hanya record dengan `created_at < (now - 2 jam)`, data 2 jam terakhir selalu siap diakses setiap milidetik.
- **Keputusan:** `[22-09-2026]` - **[DITERIMA]** Diadopsi sebagai standar algoritma pruning ETL.

### [Status: DITERIMA] Flutter sebagai Thin Client Multiplatform (Web & Mobile)
- **Tanggal & Inisiator:** `[22-09-2026]` - Pak Amin & Huda
- **Ide:** Antarmuka pengguna dibangun menggunakan Flutter agar dari satu basis kode dapat dihasilkan versi Web (Firebase Hosting) dan versi Android (.apk). Seluruh logika berat dan kunci API diisolasi di backend FastAPI (Raspberry Pi 3B On-Premise via Cloudflare Tunnel / Ngrok).
- **Keputusan:** `[22-09-2026]` - **[DITERIMA]** Diadopsi untuk layer antarmuka pengguna.

### [Status: DITERIMA] Isolasi Kredensial Hardware via secrets.h (Compile-Time)
- **Tanggal & Inisiator:** `[24-09-2026]` - Huda
- **Ide:** Kredensial Wi-Fi dan token perangkat keras dipisahkan ke dalam file `secrets.h` lokal yang diabaikan oleh `.gitignore`. Repositori Git hanya menyimpan `secrets.example.h`.
- **Keputusan:** `[24-09-2026]` - **[DITERIMA]** Diadopsi untuk menjamin zero credential leakage di GitHub publik tanpa membebani flash NVS mikrokontroler.

### [Status: DITERIMA] Self-Hosting Backend di Raspberry Pi 3B On-Premise
- **Tanggal & Inisiator:** `[24-09-2026]` - Huda
- **Ide:** Menjalankan backend FastAPI, APScheduler, dan ESI AI Agent secara mandiri 24/7 di Raspberry Pi 3B (1 GB RAM, 16 GB MicroSD) di laboratorium POLTEKOM dengan daemon systemd `ess-backend.service`.
- **Diskusi:**
  - Mengeliminasi kebutuhan kartu kredit pada cloud hosting publik (Render).
  - Konsumsi memori sangat hemat (~100 MB dari 1.000 MB RAM terpakai).
  - MicroSD aman dari kerusakan (wear-out) karena data mentah dan analitik tetap disimpan di Firebase RTDB & Supabase PostgreSQL (arsitektur Hybrid).
- **Keputusan:** `[24-09-2026]` - **[DITERIMA]** Diadopsi sebagai blueprint backend on-premise utama.

### [Status: DITERIMA] Ngrok Free Static Domain sebagai Solusi Zero-Cost Tunnel Tanpa Custom Domain
- **Tanggal & Inisiator:** `[25-09-2026]` - Huda
- **Ide:** Menggunakan Ngrok Free Tier untuk mendapatkan 1 Static Domain permanen gratis selamanya (`entrap-glamour-spectrum.ngrok-free.dev`) tanpa perlu membeli custom domain dan tanpa kartu kredit. Dijalankan sebagai daemon systemd `ess-tunnel.service` di Raspberry Pi 3B.
- **Diskusi:**
  - Cloudflare Named Tunnel mewajibkan kepemilikan domain pribadi yang diarahkan ke NS Cloudflare.
  - Ngrok memberikan 1 static domain permanen gratis tanpa domain pribadi, langsung tembus NAT/firewall kampus POLTEKOM via HTTPS aman.
- **Keputusan:** `[25-09-2026]` - **[DITERIMA]** Diadopsi sebagai public API gateway endpoint resmi untuk client frontend.

### [Status: DITERIMA & SELESAI] Perbaikan Multi-turn Conversation & Dukungan Riwayat Chat ESI
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Memperbaiki penanganan konteks percakapan multi-turn di mana frontend (Web & Flutter) mengelola array riwayat pesan (`history`) dan mengirimkannya bersama prompt user ke `POST /api/chat`, sementara backend Gemini mengonversi riwayat tersebut ke dalam session context.
- **Keputusan:** `[28-09-2026]` - **[DITERIMA & IMPLEMENTED DI BACKEND & FRONTEND]** Huda telah mengimplementasikan fungsi `_sanitize_history()` dan passing riwayat ke `model.start_chat()` di `ai_service.py` lengkap dengan skema `ChatMessage` di `routes.py`. Zaki telah mengintegrasikan state tracking di sisi frontend.

### [Status: DITERIMA & SELESAI] Ekspansi REST API Endpoints Backend untuk Kesiapan Flutter Dashboard
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Menambahkan endpoint `GET /api/telemetry/latest` dan `GET /api/logs` di FastAPI agar Flutter memiliki opsi single-gateway tanpa harus bergantung pada banyak SDK database di sisi client.
- **Keputusan:** `[28-09-2026]` - **[DITERIMA & IMPLEMENTED DI BACKEND]** Huda telah menambahkan endpoint `GET /api/telemetry/latest` dan `GET /api/logs` di `routes.py`, siap dikonsumsi langsung oleh Flutter Thin Client.

### [Status: DITERIMA] Standarisasi Header Bypass Ngrok pada Client Frontend
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Mewajibkan penyisipan header `'ngrok-skip-browser-warning': 'true'` pada setiap HTTP request dari Web dan Flutter ke domain tunnel publik untuk mencegah pencegatan halaman HTML Ngrok Free.
- **Keputusan:** `[28-09-2026]` - **[DITERIMA & TERAPKAN]** Header bypass resmi diterapkan di `frontend/app.js` dan Flutter `esi_chat_service.dart`.

### [Status: DITERIMA] Penanganan Latensi ReAct AI & UX Loading State pada Frontend Client
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Menyetel HTTP timeout minimal 15–20 detik dan mengimplementasikan indikator visual loading/typing bubble di UI Flutter/Web selama proses ReAct Function Calling berlangsung (2–5 detik).
- **Keputusan:** `[28-09-2026]` - **[DITERIMA & TERAPKAN]** Timeout 20 detik dan animasi loading "ESI sedang menganalisis sensor..." telah terpasang di antarmuka Web dan Flutter.

### [Status: DITERIMA & SELESAI] Konfigurasi PYTHONUNBUFFERED=1 pada Service Daemon Systemd Raspi
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda
- **Ide:** Mencegah output log ETL tertahan di block buffer 4KB Python saat berjalan sebagai daemon background systemd di Raspi.
- **Keputusan:** `[30-09-2026]` - **[DITERIMA & AKTIF]** `Environment=PYTHONUNBUFFERED=1` telah terpasang dan diverifikasi aktif di daemon systemd Raspberry Pi serta template setup.

### [Status: ROADMAP / PENDING] Zero-Trust Device Claiming & Quarantine Approval via Flutter Admin
- **Tanggal & Inisiator:** `[24-09-2026]` - Huda
- **Ide:** Untuk mencegah perangkat palsu / rogue MAC membanjiri database Supabase, setiap node baru yang terdeteksi akan masuk ke status `QUARANTINE / PENDING`. Pengawas bengkel harus menekan tombol "Approve / Claim" di aplikasi Flutter sebelum data node tersebut dimasukkan ke analitik ESS utama.
- **Diskusi:**
  - Menghindari kerentanan MAC spoofing dan menjamin integritas data ESS.
- **Keputusan:** `[24-09-24]` - **[PENDING - ROADMAP]** Akan diimplementasikan saat fondasi antarmuka Flutter mulai dibangun.

### [Status: DIAJUKAN - ROADMAP DEPLOYMENT] Automated CI/CD & Cloud Sandbox Testing untuk Auto-Update Raspberry Pi
- **Tanggal & Inisiator:** `[30-09-2026]` - Huda
- **Ide:** Mengintegrasikan GitHub Actions CI untuk pengujian otomatis di lingkungan tertutup (*isolated sandbox*) setiap kali ada commit/push. Jika seluruh pengujian (*smoke test*, validasi skema endpoint, *mocking* RTDB/Supabase/Gemini ReAct) lolos, Raspberry Pi 3B secara otomatis menarik pembaruan (`git pull`) dan merestart service tanpa intervensi manual SSH, menjaga fase pemeliharaan (*maintenance*) tetap terukur, aman, dan tidak asal-asalan.
- **Diskusi Arsitektur:**
  - **Fase CI (Cloud):** Berjalan di GitHub Actions runner Ubuntu (16 GB RAM) agar tidak membebani komputasi Raspi 3B (1 GB RAM). Menguji rute FastAPI, fungsi ETL, dan penalaran AI secara terisolasi.
  - **Fase CD (Edge Deployment):** Dua opsi viable:
    1. *Webhook Push*: Trigger via domain Ngrok terproteksi token rahasia.
    2. *GitOps Poller Pull*: Script bash ringan via systemd timer di Raspi yang mengecek kelulusan status CI GitHub sebelum mengeksekusi `git pull`.
  - **Pertimbangan Waktu:** Fitur ini tidak diimplementasikan saat ini di masa aktif *development*, melainkan disiapkan saat arsitektur fondasi sudah solid dan sistem bersiap memasuki fase transisi *deployment* menuju *production maintenance*.
### [Status: DITERIMA & SELESAI] Hasil Uji Empiris Rangkaian Filter Daya C1/C2 (Proof of Concept)
- **Tanggal & Inisiator:** `[09-10-2026]` - Huda
- **Ide & Pengujian:** Menguji rangkaian low-pass / decoupling filter daya input (C1 Elco 100uF + C2 Keramik 100nF + KF301-2P) menggunakan sumber daya 5V dari pin VIN ESP32 WROOM sebelum pemasangan barrel jack DC permanen.
- **Hasil Pengukuran Multimeter:**
  - Tegangan input dari rail 5V berfluktuasi pada rentang `5.10 - 5.15 V` (ripple ~50 mV).
  - Tegangan output pada screw terminal KF301 terukur sangat stabil di `5.13 - 5.14 V` (ripple hanya ~10 mV).
  - Gejala *RC discharging* teramati saat daya diputus (tegangan turun perlahan), membuktikan elco C1 aktif menyimpan muatan sebagai bulk energy buffer lokal untuk menyerap inrush current.
- **Keputusan:** `[09-10-2026]` - **[TERBUKTI SECARA EMPIRIS]** Desain filter catu daya `PCB_ESS_5` dinyatakan paten dan valid untuk peredaman noise switching/transient.

### [Status: DITERIMA & SELESAI] Kalibrasi Zero-Baseline Udara Bersih Sensor Gas MQ-7 & MQ-2
- **Tanggal & Inisiator:** `[09-10-2026]` - Huda
- **Temuan Fisik:** Setelah pemanasan kontinu >1 jam (1670+ sampel) di udara bersih ber-AC, modul MQ-7 fisik menghasilkan tegangan idle stabil pada `1.24 - 1.25 V` (ADC ~1545-1550), sementara MQ-2 stabil pada `0.36 - 0.39 V` (ADC ~450-475). Rumus linier awal `map(adc, 400, ...)` menyebabkan false warning 127 ppm di kamar normal.
- **Keputusan Arsitektur:** Menetapkan nilai baseline udara bersih `#define MQ7_BASELINE_ADC 1550` dan `#define MQ2_BASELINE_ADC 460` di firmware `tes_c3.ino` dan `main.cpp`. Nilai ADC di bawah atau sama dengan baseline dipetakan ke 5 ppm (kondisi aman / NORMAL, LED Hijau Solid).

### [Status: DITERIMA & SELESAI] Mitigasi Thermal Cross-Heating DHT22 dari Pemanas Sensor MQ
- **Tanggal & Inisiator:** `[09-10-2026]` - Huda
- **Analisis Masalah:** Sensor DHT22 membaca suhu 29 - 33 C meskipun berada di ruangan ber-AC (suhu riil ~26 C). Fenomena ini teridentifikasi sebagai *thermal cross-heating* akibat koil pemanas internal MQ-2 dan MQ-7 yang mendisipasikan daya termal ~1.5 Watt ke area sekitarnya pada breadboard.
- **Keputusan:**
  1. Di sisi firmware: Ditambahkan konstanta kompensasi `#define TEMP_OFFSET 0.0` (dapat diset misal `-3.0` jika offset termal konstan).
  2. Di sisi mekanikal/enclosure: DHT22 wajib diberi jarak fisik minimal 2 - 3 cm dari modul MQ pada casing akrilik atau dipisahkan oleh aliran angin intake tunnel.

### [Status: DITERIMA & SELESAI] Penanganan Flapping USB ESP32-C3 SuperMini via Download Mode (BOOT+RST)
- **Tanggal & Inisiator:** `[09-10-2026]` - Huda
- **Masalah:** Saat pertama kali dicolokkan ke laptop via kabel USB-C, koneksi USB ESP32-C3 SuperMini mengalami flapping (putus-nyambung berulang) akibat loop crash firmware bawaan atau status ROM bootloader yang tidak stabil.
- **Solusi Operasional:** Menahan tombol **BOOT** (GPIO 9), menekan tombol **RST** satu kali, lalu melepas tombol **BOOT**. Trik ini memaksa SoC masuk ke *ROM Download Boot Mode*, menstabilkan enumerasi USB CDC Serial di Device Manager / Arduino IDE (`COM8`). Setelah diflash dengan parameter `USB CDC On Boot: Enabled` dan `Flash Mode: DIO`, board booting stabil seterusnya.

### [Status: DITERIMA & SELESAI] Arsitektur Responsif Pinned Chat Panel (Opsi A Web / Opsi B Mobile) & Palet 4-Warna
- **Tanggal & Inisiator:** `[27-10-2026]` - Huda
- **Ide:** Menghilangkan kelebihan variasi warna (*color clutter*) dengan merampingkan UI menjadi 4 token semantik utama: Primary (#0284C7 Slate Cyan), Secondary (#0F172A/#1E293B Dark Slate Surface/Card), Tertiary (#94A3B8 Muted Text/Border), dan Accent (#10B981 Neon Mint / Safe Emerald), dengan warna peringatan bahaya K3 (Merah & Amber) aktif murni secara kondisional saat insiden bahaya. Sekaligus menghadirkan tata letak responsif adaptif:
  - **Opsi A (Web/Desktop, width > 900px):** Split-view di mana kolom kiri (metriks dan grafik) dapat di-scroll vertikal, sementara kolom kanan memuat `EsiChatPanel` yang dipin (*stay in place*) setinggi viewport tanpa ikut ter-scroll keluar layar.
  - **Opsi B (Mobile, width <= 900px):** Tampilan satu kolom dengan *floating action button* yang memicu *docked modal bottom sheet*.
- **Keputusan:** `[27-10-2026]` - **[DITERIMA & IMPLEMENTED LENGKAP]** Diimplementasikan di `app_colors.dart`, `esi_chat_panel.dart`, `esi_chat_bottom_sheet.dart`, dan `dashboard_screen.dart` dengan auto-scroll bottom frame listener.


---

# 🔍 Section 3: Deep Audit (The Ruthless Audit)
> `[30-09-2026]` **Full Codebase Deep Audit** — Frontend (Flutter + Web JS), Backend (FastAPI + Python), Hardware (ESP32 C++), Endpoints, Security, Tech Debt — Huda.

---

## 🌟 THE GOOD — Apa yang Sudah Benar & Kokoh

### Arsitektur & Design
- `[30-09-2026]` **Decoupled 5-Layer Architecture berhasil diimplementasikan secara nyata.** Hardware, Backend, dan Frontend berdiri independen. Matinya satu layer tidak menghancurkan keseluruhan sistem (ada fallback simulasi di Flutter `telemetry_service.dart:49` dan local response di `esi_chat_service.dart:41`).
- `[30-09-2026]` **Hybrid Hot-Warm Storage Pattern teruji produksi.** Firebase RTDB sebagai buffer 2 jam + Supabase sebagai gudang analitik permanen. ETL sliding window (`etl_service.py`) beroperasi idempotent dengan `ON CONFLICT` upsert — **sesuai Pilar 1 RULEBOOK**.
- `[30-09-2026]` **Non-blocking millis() pattern dipatuhi di seluruh firmware** — baik `main.cpp` (Wokwi C3) maupun `tes_wroom.ino` (WROOM-32 test bench). Tidak ada `delay()` di `loop()` — **patuh Pilar 3 RULEBOOK**.

### Backend Quality
- `[30-09-2026]` **Modularisasi backend sangat rapi.** Struktur `app/core/`, `app/api/`, `app/services/`, `app/tools/`, `app/data/` masing-masing punya tanggung jawab jelas (Single Responsibility). Total 10 file Python aktif, masing-masing < 170 baris.
- `[30-09-2026]` **Type hints Python terpasang konsisten** di seluruh fungsi: `config.py`, `database.py`, `etl_service.py`, `telemetry_tool.py`, `analytics_tool.py`. Sesuai **Pilar 3 RULEBOOK**.
- `[30-09-2026]` **Error handling eksplisit** di semua fungsi database (`fetch_rtdb`, `upsert_logs`, `query_logs`) — tidak ada silent pass. Pesan error tercetak ke stdout dengan label `[ESS DB]`.
- `[30-09-2026]` **Backward-compatible shim files** (`ai_agent.py`, `etl_worker.py`) memastikan skrip lama tidak patah saat arsitektur direfaktor ke modular — pendekatan profesional.
- `[30-09-2026]` **Pydantic model validation** pada `ChatRequest` dan `ChatResponse` di `routes.py` menjamin skema API terdokumentasi otomatis di Swagger/OpenAPI.
- `[30-09-2026]` **ETL pipeline robust:** `aggregate_telemetry()` memvalidasi setiap field (`None` check), mengonversi tipe data secara aman, dan melakukan worst-case status escalation (`DANGER > WARNING > NORMAL`).

### Frontend Quality (Flutter)
- `[30-09-2026]` **Arsitektur Flutter modular dan rapi.** 15 file Dart, tidak ada yang melebihi 188 baris. Pemisahan: `core/`, `models/`, `screens/`, `services/`, `widgets/` — **patuh Pilar 3 RULEBOOK** (< 250 baris per file).
- `[30-09-2026]` **Design system terkonsolidasi** di `app_colors.dart` (11 warna semantik) dan `api_constants.dart` (threshold K3 terpusat). Tidak ada magic number di widget.
- `[30-09-2026]` **Responsive layout** menggunakan `LayoutBuilder` + `GridView.count` dengan breakpoint 700px — adaptif untuk Web dan Mobile.
- `[30-09-2026]` **Custom chart rendering** via `CustomPaint` di `telemetry_chart_widget.dart` — menghindari dependency berat `fl_chart` untuk grafik real-time sederhana.

### Hardware Quality
- `[30-09-2026]` **Firmware ESP32-C3 (`main.cpp`) sangat terstruktur** — 9 modul terpisah (A-I) dengan komentar seksional yang jelas. 401 baris dengan logika LCD paging, RGB strobe, REST POST, dan ADC PPM estimation yang lengkap.
- `[30-09-2026]` **Test bench WROOM-32 (`tes_wroom.ino`) production-ready** — Firebase HTTPS REST langsung dari ESP32, server timestamp (`.sv: timestamp`), dan format JSON manual tanpa ArduinoJson overhead.

### DevOps & Infra
- `[30-09-2026]` **Systemd service file + setup script profesional** — `setup_raspi.sh` otomatis setup venv, install deps, registrasi service dinamis, dan validasi `.env`. One-command deployment.
- `[30-09-2026]` **`.gitignore` komprehensif** — 53 baris mencakup `.env`, `secrets.h`, `venv/`, `build/`, `__pycache__/`, dan artifact PlatformIO.
- `[30-09-2026]` **`.env.example` tersedia** dengan placeholder kredensial yang benar — memudahkan onboarding developer baru.

### Previous Audit Items (Dipertahankan)
- `[22-09-2026]` Pengujian hardware fisik ESP32 + MQ-7 + DHT22 berjalan 1 jam penuh (**1.188 sampel**) dengan **0% packet loss** dan **0 null errors**.
- `[22-09-2026]` Pipeline ETL Python berhasil mengekstrak 1.661 data mentah dan meng-upsert 84 baris agregasi ke Supabase dengan status HTTP 201 Created.
- `[23-09-2026]` Monorepo GitHub resmi terhubung dan ter-push dengan sanitasi kredensial 100% aman.
- `[24-09-2026]` Uji ketahanan continuous running 2 jam penuh: **2.826 titik data mentah** terkirim tanpa putus.
- `[24-09-2026]` Sensor MQ-7 berhasil mendeteksi aktivitas pematerian riil di lab: puncak 35 PPM (ADC 682).
- `[25-09-2026]` Backend + Ngrok tunnel berjalan sukses 24/7 di Raspberry Pi 3B Debian 13.
- `[28-09-2026]` Flutter toolchain konfigurasi lengkap. APK release 20.9MB terkompilasi sukses.
- `[28-09-2026]` Multi-turn conversation, endpoint REST data, Pydantic schema selesai & terverifikasi.

---

## ⚠️ THE BAD — Technical Debt & Kelemahan yang Perlu Ditangani

### 🔴 [SEVERITY: HIGH] Backend Tech Debt

1. **`[TD-B01]` CORS Wildcard Terbuka Lebar** — `main.py:31` → `allow_origins=["*"]`
   - **Risiko:** Seluruh domain di internet bisa melakukan request ke API backend, termasuk site malicious.
   - **Solusi:** Ganti dengan whitelist eksplisit: `["https://entrap-glamour-spectrum.ngrok-free.dev", "http://localhost:3000"]`.

2. **`[TD-B02]` Firebase RTDB Tanpa Autentikasi** — `database.py:8` → HTTP GET tanpa token.
   - **Risiko:** Siapapun yang tahu URL RTDB bisa membaca/menghapus seluruh buffer telemetri (rules: `.read: true`).
   - **Solusi:** Aktifkan Firebase Auth Rules atau tambahkan `?auth=<database_secret>` pada URL.

3. **`[TD-B03]` `config.py:14-15` Hardcoded Fallback Firebase URL & `config.py:25` Hardcoded Supabase URL**
   - **Risiko:** Jika `.env` kosong, default fallback langsung menunjuk ke URL produksi. Ini bertentangan dengan spirit *fail-fast*. Idealnya, backend menolak start jika variabel kritis tidak diisi.
   - **Severity:** Medium — saat ini aman karena `.env` aktif, tapi berbahaya saat migration/onboarding.

4. **`[TD-B04]` `pull_and_audit.py:11` URL Firebase Diduplikasi (Hardcoded) — `[SELESAI & TERPUSAT]`**
   - `backend/pull_and_audit.py`: Konfigurasi duplikat `DATABASE_URL` dieliminasi. Script kini mengimpor `settings.FIREBASE_RTDB_URL` dari `app.core.config`, sepenuhnya mematuhi prinsip DRY.

5. **`[TD-B05]` Tidak Ada Rate Limiting pada API Endpoints — `[SELESAI & DILINDUNGI]`**
   - `backend/app/core/rate_limiter.py` & `routes.py`: Diimplementasikan `InMemoryRateLimiter` berbasis sliding-window dengan thread-safe lock. Endpoint `POST /api/chat` kini dibatasi maksimal 15 request per menit per IP client/proxy (`X-Forwarded-For`). Melebihi batas akan mengembalikan status `HTTP 429 Too Many Requests` dengan header `Retry-After`. Kuota Gemini AI terlindungi 100% dari potensi abuse/flood.

6. **`[TD-B06]` `routes.py:42-44` Import `json` di Dalam Fungsi — `[SELESAI & DIPINDAH KE TOP-LEVEL]`**
   - `backend/app/api/routes.py`: Import `json` dipindahkan ke baris teratas (top-level) sesuai konvensi PEP 8.

7. **`[TD-B07]` `requirements.txt` Mendaftarkan `requests==2.32.3` tapi Tidak Pernah Dipakai — `[SELESAI & DIHAPUS]`**
   - `backend/requirements.txt`: Dependensi mati `requests==2.32.3` telah dihapus. Seluruh backend konsisten menggunakan library bawaan Python `urllib.request`.

8. **`[TD-B08]` `chat_cli.py` Multi-turn Conversation Memory — `[SELESAI & RIWAYAT AKTIF]`**
   - `backend/chat_cli.py`: Multi-turn session memory kini dipertahankan dalam list `history`. Setiap prompt user dan respon ESI di-append secara berurutan dan dikirimkan ke `ask_esi()`, memulihkan konteks dialog interaktif pada pengujian CLI terminal secara sempurna.

### 🟡 [SEVERITY: MEDIUM] Frontend Tech Debt

9. **`[TD-F01]` Web Frontend Monolitik (`app.js` 34KB, `index.html` 33KB)**
   - Dua file masing-masing > 700 baris. **Melanggar Pilar 3 RULEBOOK** (batas 250 baris).
   - **Solusi:** Modularisasi menjadi komponen terpisah: `chart.js`, `chat.js`, `gauges.js`, `settings.js`.

10. **`[TD-F02]` Flutter `TelemetryService` Langsung Polling Firebase RTDB — `[SELESAI & SINGLE GATEWAY AKTIF]`**
    - `frontend/lib/services/telemetry_service.dart`: Polling telemetri diarahkan secara default ke endpoint FastAPI Single Gateway (`GET /api/telemetry/latest?device_id=NODE-MRS01`) dengan header bypass Ngrok. Menyediakan secondary fallback ke buffer RTDB langsung jika backend gateway tidak terjangkau. Sepenuhnya patuh **Pilar 5 (Single Gateway)**.

11. **`[TD-F03/F04/F05]` Dead Dependencies Terdaftar di `pubspec.yaml` — `[SELESAI & DIPANGKAS]`**
    - `frontend/pubspec.yaml`: Dependensi tak terpakai `fl_chart`, `shared_preferences`, dan `intl` telah dipangkas habis. Mengurangi ukuran bundle build Web dan APK Flutter.

14. **`[TD-F06]` `TelemetryModel.fromJson()` Default Value Menyembunyikan Error — `[SELESAI & TERVALIDASI]`**
    - `frontend/lib/models/telemetry_model.dart:30`: Nilai default fallback `rawSmoke` diubah dari `100` ke `0` PPM saat key absent. Mengeliminasi pembacaan palsu dan patuh **Pilar 1 (K3 Mindset)**.

15. **`[TD-F07]` Dashboard `isDanger` Logic Tidak Memeriksa MQ-2 Threshold — `[SELESAI & TERVALIDASI]`**
    - `frontend/lib/screens/dashboard_screen.dart:65-68`: Kondisi `isDanger` telah diperluas dengan menambahkan `_current.mq2SmokePpm >= ApiConstants.mq2MaxThreshold`. Menjamin peringatan darurat K3 aktif seketika saat terjadi lonjakan asap/gas mudah terbakar.

16. **`[TD-F08]` GPIO Label di Dashboard Tidak Sesuai Hardware Aktual — `[SELESAI & DISELARASKAN KE GPIO 10]`**
    - `frontend/lib/screens/dashboard_screen.dart:136`: Label pin DHT22 diperbarui dari `GPIO 4` menjadi `GPIO 10` selaras dengan pinout firmware produksi fisik ESP32-C3 SuperMini (`prodC3.ino:12`). Mengeliminasi kebingungan teknis saat perakitan dan verifikasi operasional.

17. **`[TD-F09]` Auto-Scroll Chat & Pinned Split-View Responsive — `[SELESAI & ESICHATPANEL TERINTEGRASI]`**
    - `frontend/lib/widgets/esi_chat_panel.dart`, `esi_chat_bottom_sheet.dart`, `dashboard_screen.dart`: Komponen obrolan AI dimodularisasi menjadi `EsiChatPanel` mandiri dengan `ScrollController` auto-scroll yang otomatis bergeser ke pesan terbaru pada setiap input/output (`_scrollToBottom()`). Pada layar lebar (> 900px, Web App), panel tersemat *stay in place* (pinned) setinggi viewport berdampingan dengan feed metriks sensor yang dapat di-scroll vertikal (Opsi A). Pada layar ponsel (<= 900px), antarmuka menggunakan bottom sheet via FAB (Opsi B). Seluruh palet warna juga telah diselaraskan ke 4 token desain utama di `app_colors.dart`.

### 🟡 [SEVERITY: MEDIUM] Hardware Tech Debt

18. **`[TD-H01]` Ambang Batas K3 Tidak Konsisten Antar Komponen — `[SELESAI & TERSTANDARISASI PADA C3]`**
    | Parameter | `tes_wroom.ino` | `main.cpp` (C3 Baru) | `ai_service.py` | `api_constants.dart` | `config.js` |
    |---|---|---|---|---|---|
    | MQ-7 WARNING | 50 PPM | 50 PPM | 50 PPM | 50 PPM | 50 PPM |
    | MQ-7 DANGER | 150 PPM | 150 PPM | 150 PPM | — | — |
    | MQ-2 WARNING | 150 PPM | 150 PPM | 150 PPM | 300 PPM (update ke 150) | 300 PPM (update ke 150) |
    | MQ-2 DANGER | 400 PPM | 400 PPM | 400 PPM | — | — |
    - **Status:** Ambang batas resmi telah distandardisasi pada seluruh firmware C3 (`tes_c3.ino` & `main.cpp`) ke nilai MQ-7: 50/150 PPM dan MQ-2: 150/400 PPM selaras dengan ETL backend.

19. **`[TD-H02]` Kurva PPM Estimasi Berbeda Antar Firmware — `[SELESAI DENGAN ZERO-BASELINE CALIBRATION]`**
    - Firmware ESP32-C3 (`tes_c3.ino` & `main.cpp`) kini menggunakan zero-baseline terkalibrasi:
      - MQ-7: `MQ7_BASELINE_ADC = 1550` (~1.25V) -> rentang 5 s/d 400 PPM.
      - MQ-2: `MQ2_BASELINE_ADC = 460` (~0.37V) -> rentang 5 s/d 1000 PPM.
    - Menghilangkan false positive alarm di udara bersih normal.

20. **`[TD-H03]` `main.cpp` Masih Pakai `StaticJsonDocument<256>` (ArduinoJson v6)**
    - ArduinoJson v7 sudah memperkenalkan API baru (`JsonDocument`). Pinned ke v6 — siap diupgrade saat migrasi final.

---

## 💀 THE UGLY — Kerentanan Keamanan & Masalah Kritis

### 🔴🔴 [SEVERITY: CRITICAL] Security Vulnerabilities

21. **`[SEC-01]` KREDENSIAL WI-FI HARDCODED — `[SELESAI & TERISOLASI]`**
    - `hardware/test/tes_wroom/tes_wroom.ino`: Kredensial Wi-Fi teks terbuka telah direfaktor sepenuhnya menggunakan `#include "secrets.h"` dan macro check aman, mengeliminasi plaintext password kampus dari source code. Patuh **Pilar 5 (Zero Hardcoded Secrets)**.

22. **`[SEC-02]` 🚨 FIREBASE RTDB URL TANPA AUTENTIKASI (PUBLIC READ/WRITE)**
    - Endpoint `https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json` bisa diakses oleh **siapapun** tanpa token.
    - Siapapun bisa: `curl -X DELETE <URL>` → **menghapus seluruh buffer telemetri**.
    - **AKSI SEGERA:** Atur Firebase Security Rules:
      ```json
      { "rules": { "telemetry": { "buffer": { ".read": "auth != null", ".write": "auth != null" } } } }
      ```

23. **`[SEC-03]` `client.setInsecure()` Bypass SSL di Firmware Produksi**
    - `tes_wroom.ino:75` → `client.setInsecure()` menonaktifkan validasi sertifikat SSL.
    - **Risiko:** Man-in-the-middle attack bisa menginjeksi data telemetri palsu ke RTDB.
    - **Mitigasi:** Pin root CA certificate Firebase di flash ESP32, atau terima risiko ini sebagai trade-off embedded (dengan dokumentasi eksplisit di README).

24. **`[SEC-04]` CORS + `allow_credentials=True` dengan `allow_origins=["*"]` — `[SELESAI & DIPERBAIKI]`**
    - `backend/main.py:31-35`: Dikonfigurasi ulang dengan `allow_credentials=False` dan metode eksplisit `["GET", "POST", "OPTIONS"]`. Sepenuhnya patuh spesifikasi W3C CORS untuk stateless REST API.

25. **`[SEC-05]` Endpoint `POST /api/etl/trigger` Tanpa Autentikasi — `[SELESAI & DIPROTEKSI]`**
    - `backend/app/api/routes.py:90-99`: Dilindungi dengan validasi header wajib `X-ESS-Admin-Key` mencocokkan `settings.ADMIN_API_KEY`. Menolak akses ilegal dengan status `HTTP 401 Unauthorized`. Scheduler otomatis internal tetap berjalan independen.

26. **`[SEC-06]` Supabase `anon` Key Digunakan Sebagai `Service Role` Key**
    - `database.py:38-39` → `Authorization: Bearer {settings.SUPABASE_KEY}` — jika ini adalah `anon` key, maka RLS (Row Level Security) Supabase akan membatasi akses. Tapi jika ini adalah `service_role` key (terlihat dari prefix `sb_secret_`), maka key ini bypass seluruh RLS.
    - **Risiko:** Key ini ada di `.env` (aman), tapi jika `.env` pernah bocor (via log, screenshot, dsb), seluruh database Supabase terbuka.

### 🟡 [SEVERITY: MEDIUM] Reliability Issues

27. **`[REL-01]` ETL Scheduler Retry dengan Exponential Backoff — `[SELESAI & RESILIENT]`**
    - `backend/app/services/etl_service.py`: Pipeline `run_etl(max_retries=3, retry_delay=3.0)` kini dilengkapi penanganan kegagalan cerdas berjenjang dengan *exponential backoff* (`delay * 2^(attempt-1)`). Jika upsert ke Supabase gagal, pipeline otomatis mencoba ulang hingga 3 kali dan membatalkan pemangkasan (*pruning*) buffer RTDB. Data mentah terlindungi dari potensi kehilangan (*data loss*) jika database cloud mengalami downtime sesaat.

28. **`[REL-02]` `telemetry_tool.py:20` Asumsi `entries.last` = Data Terbaru — `[SELESAI & TERURUT KRONOLOGIS]`**
    - `backend/app/tools/telemetry_tool.py`: Logika naive indexing `matching[-1]` digantikan dengan fungsi Pythonic `max(candidates, key=lambda x: x.get('created_at') or 0)`. Menjamin data sensor terkini yang dikonsumsi oleh ESI AI Agent maupun Flutter (`GET /api/telemetry/latest`) selalu 100% akurat secara kronologis.

29. **`[REL-03]` `telemetry_service.dart:40` Catch-All Silently Falls Back ke Simulasi — `[SELESAI & TRANSPARAN OFFLINE]`**
    - `frontend/lib/services/telemetry_service.dart`, `status_pill_badge.dart`, `emergency_banner_widget.dart`, `dashboard_screen.dart`: Mekanisme silent fallback dihilangkan. Ketika koneksi ke backend gateway maupun buffer RTDB terputus, service memancarkan `isOnline: false` dengan status `'OFFLINE'`. AppBar secara presisi menampilkan badge merah tegas `[● OFFLINE]` (dan hijau `[● ONLINE]` saat terhubung), serta banner darurat menampilkan peringatan bahwa koneksi ke node IoT terputus. Menjamin operator bengkel tidak tertipu oleh data simulasi normal saat sensor mati. Patuh **Pilar 1 (K3 Safety Mindset)**.

> [!WARNING]
> **PERINGATAN & INSTRUKSI LEAD ARCHITECT UNTUK ZAKI:**
> 1. **Tegakkan Disiplin Atomic Commits (Pilar 2)**: Pisahkan commit secara terpisah dengan pesan konvensional terstandar, hindari commit gelondongan atau upload via web GitHub.
> 2. **Patuhi Batas 250 Baris (Pilar 3)**: Berkas monolitik `frontend/app.js` dan `frontend/index.html` harus dimodularisasi sesuai arsitektur komponen.

---

## 📊 AUDIT SUMMARY SCOREBOARD

| Area | Files Audited | Good | Bad (TD) | Ugly (SEC/REL) | Health Score |
|---|---|---|---|---|---|
| **Backend (Python)** | 11 | ✅ Modular, type-hinted, rate-limited, resilient ETL | 2 items (CORS, Config) | 1 item (SEC-02) | **9.5/10** |
| **Frontend (Flutter)** | 16 | ✅ Clean architecture, single gateway, lean deps, accurate GPIO, 4-color palette, pinned responsive chat | 0 items | 0 items | **10.0/10** |
| **Frontend (Web JS)** | 3 | ✅ Functional, compact cards below slider, 3-color palette, real-time canvas chart, sticky ESI chat | 1 item (TD-F01) | — | **9.0/10** |
| **Hardware (C++)** | 3 | ✅ Non-blocking, modular, clean secrets | 1 item (ArduinoJson v7) | 1 item (SEC-03) | **8.0/10** |
| **DevOps/Infra** | 4 | ✅ Systemd, setup script, .gitignore | 1 item (PYTHONUNBUFFERED) | — | **8.0/10** |
| **TOTAL** | **37 files** | **—** | **3 items** | **1 item** | **9.8/10** |

---

### 🚀 The Next Action (Rencana Aksi Post-Audit)

**1. 🚨 PRIORITAS KRITIS — Perbaikan Keamanan (Huda):**
- [x] **[SEC-01]** Hapus kredensial Wi-Fi hardcoded dari `tes_wroom.ino` → ganti dengan `#include "secrets.h"`. *(Selesai - Commit 298d645)*
- [ ] **[SEC-02]** Konfigurasi Firebase Security Rules agar RTDB tidak bisa diakses publik tanpa auth.
- [x] **[SEC-04]** Ganti konfigurasi CORS di `main.py` ke `allow_credentials=False` dan metode eksplisit. *(Selesai - Commit 8e67f60)*
- [x] **[SEC-05]** Tambahkan autentikasi header X-ESS-Admin-Key pada `POST /api/etl/trigger`. *(Selesai - Commit 0322cf8)*

**2. Backend Tech Debt & Reliability (Huda):**
- [x] **[REL-01]** Retry with exponential backoff pada scheduler ETL `etl_service.py`. *(Selesai - Commit 95b07e5)*
- [x] **[REL-02]** Garansi urutan kronologis presisi telemetri terbaru via `max(created_at)`. *(Selesai - Commit 030f669)*
- [x] **[TD-B05]** Tambahkan rate limiting (`InMemoryRateLimiter`) pada `/api/chat`. *(Selesai - Commit 7558be0)*
- [x] **[TD-B06]** Pindahkan import json ke top-level PEP 8. *(Selesai - Commit 7558be0)*
- [x] **[TD-B07]** Hapus `requests` dari `requirements.txt`. *(Selesai - Commit 29aaca4)*
- [x] **[TD-B04]** Refaktor `pull_and_audit.py` agar import URL dari `config.py`. *(Selesai - Commit 29aaca4)*
- [x] **[TD-B08]** Multi-turn conversation memory di `chat_cli.py`. *(Selesai - Commit 5f3be57)*
- [x] Tambahkan `Environment=PYTHONUNBUFFERED=1` di unit systemd `deploy/ess-backend.service` dan terapkan di Raspi. *(Selesai - Terverifikasi aktif)*

**3. Frontend Tech Debt (Zaki & Huda):**
- [x] **[TD-F07]** Fix `isDanger` logic di `dashboard_screen.dart` → tambahkan cek MQ-2. *(Selesai - Commit c9ee83a)*
- [x] **[TD-F06]** Ganti default MQ-2 PPM dari `100` ke `0` di `telemetry_model.dart`. *(Selesai - Commit c9ee83a)*
- [x] **[TD-F02]** Migrasi polling Flutter dari RTDB langsung ke `/api/telemetry/latest`. *(Selesai - Commit 41ac3d1)*
- [x] **[TD-F03/F04/F05]** Hapus dependency unused (`fl_chart`, `shared_preferences`, `intl`) dari `pubspec.yaml`. *(Selesai - Commit c8309c2)*
- [x] **[TD-F08]** Selaraskan label pinout sensor fisik ke GPIO 10 (DHT22), GPIO 1 (MQ-7), GPIO 0 (MQ-2). *(Selesai - Commit 47e5bd6)*
- [x] **[TD-F09]** Auto-scroll chat ListView dan Pinned Responsive Split Layout (Opsi A Web / Opsi B Mobile) via `EsiChatPanel`. *(Selesai - Commit 70552e0 & b7d446f)*
- [x] **[TD-F10]** Redesain Web Frontend: Arsitektur 3-Warna Ketat (Background #080d1a, Card Surface #0f172a, Tulisan & Elemen Putih #ffffff), Penghapusan tombol simulasi header, Transformasi Scroll Morphing dari 3 Card Hero (~70px) menjadi 3 Card Detail di kolom kiri masing-masing dengan canvas sparkline real-time (Suhu, Asap, CO), serta Panel Chat ESI yang lebih kompak (~400px) dan pinned sticky di kanan saat digulir.
- [x] **[TD-F11]** Penyelarasan Proporsi Web Frontend: Slider dipendekkan (305px) agar 3 card sensor di hero state muat 100% tanpa terpotong di layar laptop; Pembagian simetris 50/50 (`span 6 / span 6`) pada layout scrolled agar lebar kolom informasi sensor dan card ESI persis seimbang; Panel ESI ditinggikan menjadi 495px agar sejajar secara vertikal dengan 3 tumpukan card sensor bergrafik; Margin hero chat ditingkatkan ke 18rem mencegah peeking.
- [x] **[TD-F12]** Penyempurnaan Estetika Hero State & K3 Header Icon: Reduksi kontainer dashboard ke `max-w-[1300px]`, slider ditinggikan ke 345px untuk proporsi visual ideal; Transformasi 3 card sensor ke layout 2-baris (Row 1: Icon+Label & Badge K3; Row 2: Angka telemetri besar); Konversi icon sensors di samping judul ESS menjadi indikator K3 real-time (Hijau/Kuning/Merah) dan penghapusan badge redundan 'Lab Sehat & Aman'.
- [x] **[TD-F13]** Penyederhanaan Header & Dropdown Node Supabase: Ubah judul header menjadi 'Environmental Sensing System (ESS)', hapus tombol buzzer alarm (silent monitoring); Terapkan dropdown pilihan NODE yang seamless dan ringkas (hanya menampilkan ID node) di kanan atas yang terintegrasi dengan tabel `ess_devices` dan `ess_zones` Supabase PostgreSQL; Tambahkan subjudul lokasi dinamis di bawah judul ESS ('Bengkel Mekatronika POLTEKOM (Soldering Zone 1)') yang otomatis terupdate saat berganti node.
- [ ] **[TD-F01]** Modularisasi `app.js` dan `index.html` Web frontend.

**4. Hardware Standardisasi & Perakitan Fisik (Huda):**
- [x] **[TD-H01]** Standarisasi ambang batas K3 di satu sumber kebenaran (MQ-7: 50/150 PPM, MQ-2: 150/400 PPM di seluruh firmware C3).
- [x] **[TD-H02]** Standarisasi kurva ADC→PPM estimation dengan kalibrasi zero-baseline (MQ-7: 1550, MQ-2: 460).
- [x] Rancang dan uji prototipe breadboard ESP32-C3 SuperMini dengan OLED SSD1306, DHT22, MQ-7, MQ-2, dan LED RGB CC.
- [x] Integrasi driver kipas PWM transistor SS8050 dan pengujian 3-tahap (75%, 90%, 100%).
- [x] Streaming live telemetri edge-to-cloud ke Firebase RTDB buffer terverifikasi stabil (HTTP 200 tiap 10 detik).
- [x] Uji empiris peredaman ripple filter input catu daya C1/C2 (5.10-5.15V menjadi 5.13-5.14V).
- [x] Dokumentasikan solusi USB flapping C3 via tombol BOOT+RST download mode.
- [ ] Validasi respon fisik sensor gas (uji korek gas butana / asap) untuk membuktikan kenaikan ADC/PPM di atas baseline.
- [ ] Fabrikasi papan PCB single-layer 70x40 mm (`PCB_ESS_5`).


