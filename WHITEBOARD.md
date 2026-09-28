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
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Memperbaiki penanganan konteks percakapan multi-turn di mana frontend (Web & Flutter) mengelola array riwayat pesan (`history`) dan mengirimkannya bersama prompt user ke `POST /api/chat`, sementara backend Gemini mengonversi riwayat tersebut ke dalam session context.
- **Keputusan:** `[28-09-2026]` - **[DITERIMA & IMPLEMENTED DI FRONTEND]** Zaki telah selesai mengintegrasikan state tracking `history` di Web (`frontend/app.js`) dan Flutter (`EsiChatService` & `EsiChatBottomSheet`). Backend (Huda) tinggal menyelaraskan ekstraksi `history` di `ai_service.py`.

### [Status: DISETUJUI FRONTEND] Ekspansi REST API Endpoints Backend untuk Kesiapan Flutter Dashboard
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Menambahkan endpoint `GET /api/telemetry/latest` dan `GET /api/logs` di FastAPI agar Flutter memiliki opsi single-gateway tanpa harus bergantung pada banyak SDK database di sisi client.
- **Keputusan:** `[28-09-2026]` - **[DISETUJUI FRONTEND]** Zaki menyetujui pendekatan single-gateway ini demi simplisitas Flutter Thin Client. Sembari menunggu backend Raspi mengimplementasikannya, frontend tetap memantau Firebase RTDB Hot Buffer secara langsung.

### [Status: DITERIMA] Standarisasi Header Bypass Ngrok pada Client Frontend
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Mewajibkan penyisipan header `'ngrok-skip-browser-warning': 'true'` pada setiap HTTP request dari Web dan Flutter ke domain tunnel publik untuk mencegah pencegatan halaman HTML Ngrok Free.
- **Keputusan:** `[28-09-2026]` - **[DITERIMA & TERAPKAN]** Header bypass resmi diterapkan di `frontend/app.js` dan Flutter `esi_chat_service.dart`.

### [Status: DITERIMA] Penanganan Latensi ReAct AI & UX Loading State pada Frontend Client
- **Tanggal & Inisiator:** `[28-09-2026]` - Huda & Zaki
- **Ide:** Menyetel HTTP timeout minimal 15–20 detik dan mengimplementasikan indikator visual loading/typing bubble di UI Flutter/Web selama proses ReAct Function Calling berlangsung (2–5 detik).
- **Keputusan:** `[28-09-2026]` - **[DITERIMA & TERAPKAN]** Timeout 20 detik dan animasi loading "ESI sedang menganalisis sensor..." telah terpasang di antarmuka Web dan Flutter.

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
- `[28-09-2026]` **Integrasi Layer 5 Frontend Client (Zaki) selesai 100%:**
  - Web Frontend (`frontend/app.js` & `frontend/config.js`) resmi terhubung ke gateway Ngrok dengan header bypass `'ngrok-skip-browser-warning': 'true'`.
  - Penanganan latensi AI ESI berhasil diterapkan: timeout dinaikkan ke 20 detik dan animasi loading / typing bubble ("ESI sedang menganalisis sensor...") aktif di UI Web dan Flutter.
  - Multi-turn conversation state (`history`) aktif di Web dan Flutter Client.
  - Toolchain Flutter & Android SDK berhasil dikonfigurasi: `Android SDK 36.0.0 (cmdline-tools)`, lisensi Android disetujui, dan seluruh status `flutter doctor` centang hijau (`[✓] Flutter`, `[✓] Android toolchain`, `[✓] Chrome`, `[✓] Android Studio`).
  - Audit kode Flutter (`flutter analyze`): **No issues found!** (0 error, 0 warning) pada 15 file arsitektur modular yang 100% mematuhi batas < 250 baris Pilar 3 RULEBOOK.md.
  - Uji koneksi Hot Buffer Firebase RTDB live: **4.591 data telemetri riil** dari `NODE-MRS01` terbaca sempurna.

### ⚠️ The Bad / Technical Debt to Address
- `[25-09-2026]` **[TERSELESAIKAN]** Chatbot di Web Frontend (`frontend/app.js`) resmi terhubung ke `POST /api/chat` Ngrok publik dan dilengkapi smart local fallback jika server sedang offline.
- `[28-09-2026]` Tunnel Ngrok di Raspberry Pi saat ini berstatus offline sementara (`ERR_NGROK_3200`) selama proses maintenance service backend oleh Huda di lab. Frontend otomatis fallback ke local reasoning hingga daemon `ess-tunnel.service` di Raspi online kembali.
- `[28-09-2026]` Parameter `history` pada `POST /api/chat` di backend masih perlu diselaraskan di `ai_service.py` oleh Huda agar session memory Gemini aktif.
- `[28-09-2026]` Backend belum menyediakan endpoint REST data (`/api/telemetry/latest`, `/api/logs`) untuk layar gauge & chart Flutter jika tidak mengakses direct database.
- `[28-09-2026]` Daemon systemd di Raspi belum memiliki `PYTHONUNBUFFERED=1`, menyebabkan log output tertahan di buffer 4KB.

### 🚀 The Next Action (Rencana Aksi Selanjutnya)

**1. Sisi Backend (Huda):**
- [ ] Perbaiki bug multi-turn conversation di `backend/app/services/ai_service.py` dengan mengonversi list `history` ke format pesan Gemini (`role: user / model`).
- [ ] Tambahkan endpoint data di `backend/app/api/routes.py`:
  - `GET /api/telemetry/latest`: pembacaan real-time buffer RTDB untuk gauges Flutter.
  - `GET /api/logs`: pembacaan riwayat agregasi menit Supabase untuk grafik Flutter.
- [ ] Tambahkan `Environment=PYTHONUNBUFFERED=1` di unit systemd `deploy/ess-backend.service` dan terapkan di Raspi.
- [ ] Nyalakan kembali daemon `ess-tunnel.service` di Raspberry Pi agar public gateway Ngrok aktif.

**2. Sisi Frontend (Zaki & Web/Flutter Client):**
- [x] Perbarui `frontend/config.js` agar `BACKEND_API_URL` mengarah ke URL publik: `https://entrap-glamour-spectrum.ngrok-free.dev`. *(Selesai)*
- [x] Sambungkan logika chat di `frontend/app.js` dengan memanggil `POST /api/chat` (sertakan header `ngrok-skip-browser-warning: true`, payload `history`, timeout 20s, dan typing bubble). *(Selesai)*
- [x] Selesaikan inisialisasi struktur Flutter monorepo (`frontend/lib/`) dan konfigurasi toolchain Android APK (`cmdline-tools`). *(Selesai)*
- [ ] Lakukan uji coba build Android APK (`flutter build apk`) dan tes rendering Web di Chrome.
- [ ] Verifikasi live call end-to-end `POST /api/chat` setelah daemon tunnel Ngrok diaktifkan kembali oleh Huda.

**3. Sisi Edge Hardware & Pengujian (Huda):**
- [ ] Validasi pengujian respon gas fisik (uji tiup asap/korek gas/solder) untuk verifikasi transisi status ESS dari `NORMAL` ke `WARNING` / `DANGER` dan pencatatan anomali ke `ess_anomalies`.
- [ ] Tunggu kedatangan komponen ESP32-C3 Super Mini + MQ-2 + Kipas + Driver Transistor + RGB LED untuk refactor rangkaian fisik edge node.
