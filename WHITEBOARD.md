# 📋 WHITEBOARD (The Living Plan & Scratchpad)

Dokumen kerja aktif untuk mencatat fokus berjalan, arsip ide tim, serta evaluasi audit teknis sistem **Smart Environmental Sensing System (ESS)**.

---

# 🎯 Section 1: Current Grand Plan
> [!IMPORTANT]
> **Fokus Utama Saat Ini:** Penyempurnaan backend untuk integrasi Flutter (perbaikan bug multi-turn ESI, ekspansi endpoint REST data telemetri/log, `PYTHONUNBUFFERED=1` di daemon Raspi), penyambungan Web Frontend ke Ngrok, dan pengujian fisik respon anomali gas.
> **Affected Areas:** `backend/`, `frontend/`, `deploy/`.
> **Success Criteria:** 
> 1. ESI AI Agent (`POST /api/chat`) mampu mengingat konteks percakapan bertingkat (*multi-turn conversation*) dari array `history`.
> 2. Backend menyediakan endpoint data siap pakai untuk Flutter (`GET /api/telemetry/latest` dan `GET /api/logs`).
> 3. Daemon systemd `ess-backend.service` di Raspberry Pi terkonfigurasi `PYTHONUNBUFFERED=1` agar log journal real-time.
> 4. Chatbot frontend terhubung secara riil ke endpoint `POST /api/chat` ESI AI Agent di Raspi (bukan simulasi string).
> 5. Dashboard menampilkan data real-time RTDB sekaligus tren agregat historis dari Supabase `ess_logs`.
> 6. Terujinya respon lonjakan gas/asap fisik sehingga terpicu status WARNING/DANGER dan tercatat di `ess_anomalies`.

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

### [Status: DITERIMA] Perbaikan Multi-turn Conversation & Dukungan Riwayat Chat ESI
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda
- **Ide:** Memperbaiki bug pada `ai_service.py` di mana parameter `history` diabaikan, sehingga ESI dapat mengingat percakapan sebelumnya dari payload Flutter/Web.
- **Keputusan:** `[28-09-2026]` - **[DITERIMA]** Disetujui untuk diimplementasikan, menunggu eksekusi perbaikan kode.

### [Status: DIAJUKAN] Ekspansi REST API Endpoints Backend untuk Kesiapan Flutter Dashboard
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda
- **Ide:** Menambahkan endpoint `GET /api/telemetry/latest` dan `GET /api/logs` di FastAPI agar Flutter memiliki opsi single-gateway tanpa harus bergantung pada banyak SDK database di sisi client.
- **Keputusan:** `[28-09-2026]` - **[DIAJUKAN]** Membutuhkan koordinasi dan insight lebih lanjut dari Zaki terkait arsitektur konsumsi data di sisi frontend.

### [Status: DIAJUKAN] Konfigurasi PYTHONUNBUFFERED=1 pada Service Daemon Systemd Raspi
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda
- **Ide:** Mencegah output log ETL tertahan di block buffer 4KB Python saat berjalan sebagai daemon background systemd di Raspi.
- **Keputusan:** `[28-09-2026]` - **[DIAJUKAN]** Disiapkan untuk diterapkan pada jadwal pemeliharaan Raspberry Pi berikutnya.

### [Status: ROADMAP / PENDING] Zero-Trust Device Claiming & Quarantine Approval via Flutter Admin
- **Tanggal & Inisiator:** `[24-09-2026]` - Huda
- **Ide:** Untuk mencegah perangkat palsu / rogue MAC membanjiri database Supabase, setiap node baru yang terdeteksi akan masuk ke status `QUARANTINE / PENDING`. Pengawas bengkel harus menekan tombol "Approve / Claim" di aplikasi Flutter sebelum data node tersebut dimasukkan ke analitik ESS utama.
- **Diskusi:**
  - Menghindari kerentanan MAC spoofing dan menjamin integritas data ESS.
- **Keputusan:** `[24-09-24]` - **[PENDING - ROADMAP]** Akan diimplementasikan saat fondasi antarmuka Flutter mulai dibangun.

---

# 🔍 Section 3: Audit Plan (The Ruthless Audit)

### 🌟 The Good
- `[22-09-2026]` Pengujian hardware fisik ESP32 + MQ-7 + DHT22 berjalan 1 jam penuh (**1.188 sampel**) dengan **0% packet loss** dan **0 null errors**.
- `[22-09-2026]` Pipeline ETL Python berhasil mengekstrak 1.661 data mentah dan meng-upsert 84 baris agregasi ke Supabase dengan status HTTP 201 Created.
- `[23-09-2026]` Monorepo GitHub resmi terhubung dan ter-push dengan sanitasi kredensial 100% aman.
- `[24-09-2026]` Skema relasional Supabase di-rebrand secara bersih menjadi prefix `ess_` (`ess_zones`, `ess_devices`, `ess_logs`, `ess_anomalies`).
- `[24-09-2026]` Uji ketahanan continuous running 2 jam penuh berhasil gemilang: **2.826 titik data mentah** terkirim dari hardware ke Firebase RTDB tanpa putus.
- `[24-09-2026]` Sensor MQ-7 berhasil mendeteksi aktivitas pematerian (*soldering*) riil di lab: konsentrasi gas naik mulus dari 5 PPM ke 21–25 PPM dengan puncak 35 PPM (ADC 682).
- `[25-09-2026]` Backend FastAPI + APScheduler berjalan sukses sebagai systemd daemon di Raspberry Pi 3B Debian 13 (`aarch64`).
- `[25-09-2026]` Eksekusi ETL perdana di Raspi sukses: 187 baris agregat ter-upsert ke Supabase `ess_logs` dan 3.337 data usang RTDB terpotong otomatis via sliding window.
- `[25-09-2026]` Ngrok static tunnel online dengan HTTPS permanen `https://entrap-glamour-spectrum.ngrok-free.dev` (`GET /health` dan `POST /api/chat` terverifikasi 200 OK dari internet publik).

### ⚠️ The Bad / Technical Debt to Address
- `[25-09-2026]` Chatbot di Web Frontend (`frontend/app.js`) masih menggunakan simulasi kecocokan string lokal, belum memanggil `POST /api/chat` ke gateway backend publik.
- `[28-09-2026]` Parameter `history` pada `POST /api/chat` diabaikan oleh `ask_esi`, menyebabkan percakapan multi-turn di Flutter kehilangan memori konteks percakapan lampau.
- `[28-09-2026]` Backend belum menyediakan endpoint REST data (`/api/telemetry/latest`, `/api/logs`) untuk layar gauge & chart Flutter jika tidak mengakses direct database.
- `[28-09-2026]` Daemon systemd di Raspi belum memiliki `PYTHONUNBUFFERED=1`, menyebabkan log output tertahan di buffer 4KB.

### 🚀 The Next Action (Rencana Aksi Selanjutnya)

**1. Sisi Backend (Huda):**
- [ ] Perbaiki bug multi-turn conversation di `backend/app/services/ai_service.py` dengan mengonversi list `history` ke format pesan Gemini (`role: user / model`).
- [ ] Tambahkan endpoint data di `backend/app/api/routes.py`:
  - `GET /api/telemetry/latest`: pembacaan real-time buffer RTDB untuk gauges Flutter.
  - `GET /api/logs`: pembacaan riwayat agregasi menit Supabase untuk grafik Flutter.
- [ ] Tambahkan `Environment=PYTHONUNBUFFERED=1` di unit systemd `deploy/ess-backend.service` dan terapkan di Raspi.

**2. Sisi Frontend (Zaki & Web/Flutter Client):**
- [ ] Perbarui `frontend/config.js` agar `BACKEND_API_URL` mengarah ke URL publik: `https://entrap-glamour-spectrum.ngrok-free.dev`.
- [ ] Sambungkan logika chat di `frontend/app.js` dengan memanggil `POST /api/chat` (sertakan header `ngrok-skip-browser-warning: true` dan `Content-Type: application/json`).
- [ ] Mulai inisialisasi struktur Flutter monorepo (`frontend/lib/`).

**3. Sisi Edge Hardware & Pengujian (Huda):**
- [ ] Validasi pengujian respon gas fisik (uji tiup asap/korek gas/solder) untuk verifikasi transisi status ESS dari `NORMAL` ke `WARNING` / `DANGER` dan pencatatan anomali ke `ess_anomalies`.
- [ ] Tunggu kedatangan komponen ESP32-C3 Super Mini + MQ-2 + Kipas + Driver Transistor + RGB LED untuk refactor rangkaian fisik edge node.
