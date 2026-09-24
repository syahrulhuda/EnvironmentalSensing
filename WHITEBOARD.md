# 📋 WHITEBOARD (The Living Plan & Scratchpad)

Dokumen kerja aktif untuk mencatat fokus berjalan, arsip ide tim, serta evaluasi audit teknis sistem **Environmental Sensing & K3 Intelligent Monitoring**.

---

# 🎯 Section 1: Current Grand Plan
> [!IMPORTANT]
> **Fokus Utama Saat Ini:** Peletakan pondasi monorepo, inisialisasi repositori Git, dan persiapan backend FastAPI + AI Gemini Tool Calling di Hugging Face.
> **Affected Areas:** `hardware/`, `backend/`, repositori GitHub monorepo.
> **Success Criteria:** 
> 1. Struktur monorepo 3-folder (`hardware/`, `backend/`, `frontend/`) terinisialisasi rapi.
> 2. Kredensial terlindungi aman di `.gitignore`.
> 3. Repositori GitHub terhubung dan sinkron.
> 4. Backend FastAPI siap menampung worker ETL dan endpoint `/api/chat`.

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
- **Ide:** Antarmuka pengguna dibangun menggunakan Flutter agar dari satu basis kode dapat dihasilkan versi Web (Firebase Hosting) dan versi Android (.apk). Seluruh logika berat dan kunci API diisolasi di backend FastAPI (Hugging Face).
- **Keputusan:** `[22-09-2026]` - **[DITERIMA]** Diadopsi untuk layer antarmuka pengguna.

### [Status: DITERIMA] Isolasi Kredensial Hardware via secrets.h (Compile-Time)
- **Tanggal & Inisiator:** `[24-09-2026]` - Huda
- **Ide:** Kredensial Wi-Fi dan token perangkat keras dipisahkan ke dalam file `secrets.h` lokal yang diabaikan oleh `.gitignore`. Repositori Git hanya menyimpan `secrets.example.h`.
- **Keputusan:** `[24-09-2026]` - **[DITERIMA]** Diadopsi untuk menjamin zero credential leakage di GitHub publik tanpa membebani flash NVS mikrokontroler.

### [Status: ROADMAP / PENDING] Zero-Trust Device Claiming & Quarantine Approval via Flutter Admin
- **Tanggal & Inisiator:** `[24-09-2026]` - Huda
- **Ide:** Untuk mencegah perangkat palsu / rogue MAC membanjiri database Supabase, setiap node baru yang terdeteksi akan masuk ke status `QUARANTINE / PENDING`. Pengawas bengkel harus menekan tombol "Approve / Claim" di aplikasi Flutter sebelum data node tersebut dimasukkan ke analitik K3 utama.
- **Diskusi:**
  - Menghindari kerentanan MAC spoofing dan menjamin integritas data K3.
- **Keputusan:** `[24-09-2026]` - **[PENDING - ROADMAP]** Akan diimplementasikan saat fondasi antarmuka Flutter mulai dibangun.

---

# 🔍 Section 3: Audit Plan (The Ruthless Audit)

### 🌟 The Good
- `[22-09-2026]` Pengujian hardware fisik ESP32 + MQ-7 + DHT22 berjalan 1 jam penuh (**1.188 sampel**) dengan **0% packet loss** dan **0 null errors**.
- `[22-09-2026]` Pipeline ETL Python berhasil mengekstrak 1.661 data mentah dan meng-upsert 84 baris agregasi ke Supabase dengan status HTTP 201 Created.
- `[23-09-2026]` Monorepo GitHub resmi terhubung dan ter-push dengan sanitasi kredensial 100% aman.
- `[24-09-2026]` Skema relasional Supabase (`zones`, `devices`, `workshop_k3_logs`, `safety_incidents`) berhasil dirancang dan di-seed dengan `NODE-MRS01`.
- `[24-09-2026]` Uji ketahanan continuous running 2 jam penuh berhasil gemilang: **2.826 titik data mentah** terkirim dari hardware ke Firebase RTDB tanpa putus.
- `[24-09-2026]` Pipeline ETL 2-dimensi berhasil memadatkan 2.826 data menjadi **142 baris analitik 1-menitan** di Supabase (HTTP 201) dan memangkas 429 titik data usang (> 2 jam) via HTTP PATCH sliding window.
- `[24-09-2026]` AI Agent "ESI" (`gemini-flash-lite-latest`) berhasil terintegrasi dengan ReAct Tool Calling ganda: sukses menarik data telemetri live detik ini dari Firebase dan data historis analitik dari Supabase PostgreSQL.

### ⚠️ The Bad / Technical Debt to Address
- `[24-09-2026]` Layanan cloud hosting publik (Render) meminta verifikasi kartu kredit/debit meskipun pada paket Free Tier ($0), sehingga untuk saat ini backend dijalankan secara lokal (`backend/venv`) dengan opsi migrasi ke Vercel + GitHub Actions Cron saat siap dideploy publik.

### 🚀 The Next Action
- Lakukan validasi pengujian respon gas fisik (uji tiup asap rokok/korek gas/solder) untuk memverifikasi transisi status K3 dari `NORMAL` ke `WARNING` / `DANGER`.
- Siapkan kontrak API (`/api/chat`, `/health`, query Supabase) untuk diserahkan ke Zaki dalam rangka peletakan fondasi antarmuka Flutter (Web & Android).
