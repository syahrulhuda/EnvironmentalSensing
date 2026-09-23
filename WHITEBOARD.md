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
- **Tanggal & Inisiator:** `[21-09-2026]` - Huda (Lead Researcher) & Antigravity (AI Architect)
- **Ide:** Menggabungkan Firebase RTDB sebagai buffer cepat (Hot Storage 2 jam terakhir) dan Supabase PostgreSQL sebagai gudang analitik permanen (Warm Storage).
- **Diskusi:**
  - RTDB gratis memiliki batas 1 GB. Jika menyimpan data per 3 detik selamanya, kuota akan habis dalam beberapa bulan.
  - Dengan membersihkan data lama (> 2 jam) di RTDB dan memadatkannya menjadi agregat 1-menitan di Supabase, kuota RTDB terjaga di bawah 5 MB selamanya, dan Supabase mampu menyimpan data hingga 7 tahun.
- **Keputusan:** `[21-09-2026]` - **[DITERIMA]** Berhasil diuji coba secara fisik dengan 1.661 data mentah terkonversi menjadi 84 baris di PostgreSQL.

### [Status: DITERIMA] FIFO Continuous Sliding Window 2 Jam di RTDB
- **Tanggal & Inisiator:** `[22-09-2026]` - Huda (Lead Researcher)
- **Ide:** Mekanisme pemangkasan (*pruning*) RTDB tidak boleh menghapus seluruh data secara berkala (*flush & refill*), melainkan mempertahankan rentang waktu bergerak 2 jam terakhir (`now - 2 hours`) secara kontinu.
- **Diskusi:**
  - Jika data dihapus total, pengguna yang mengakses chatbot sesaat setelah pembersihan akan kehilangan konteks data.
  - Dengan menghapus hanya record dengan `created_at < (now - 2 jam)`, data 2 jam terakhir selalu siap diakses setiap milidetik.
- **Keputusan:** `[22-09-2026]` - **[DITERIMA]** Diadopsi sebagai standar algoritma pruning ETL.

### [Status: DITERIMA] Flutter sebagai Thin Client Multiplatform (Web & Mobile)
- **Tanggal & Inisiator:** `[22-09-2026]` - Pengawas Lapangan & Huda
- **Ide:** Antarmuka pengguna dibangun menggunakan Flutter agar dari satu basis kode dapat dihasilkan versi Web (Firebase Hosting) dan versi Android (.apk). Seluruh logika berat dan kunci API diisolasi di backend FastAPI (Hugging Face).
- **Keputusan:** `[22-09-2026]` - **[DITERIMA]** Diadopsi untuk layer antarmuka pengguna.

---

# 🔍 Section 3: Audit Plan (The Ruthless Audit)

### 🌟 The Good
- `[22-09-2026]` Pengujian hardware fisik ESP32 + MQ-7 + DHT22 berjalan 1 jam penuh (**1.188 sampel**) dengan **0% packet loss** dan **0 null errors**.
- `[22-09-2026]` Pipeline ETL Python berhasil mengekstrak 1.661 data mentah dan meng-upsert 84 baris agregasi ke Supabase dengan status HTTP 201 Created.
- `[22-09-2026]` Sensor MQ-7 menunjukkan kurva stabilisasi preheating yang sangat baik (ADC turun dari 420 ke 260 dengan noise deviasi < 0.22%).

### ⚠️ The Bad / Technical Debt to Address
- `[23-09-2026]` Kredensial Supabase dan Firebase saat ini masih tersimpan langsung di dalam file uji coba `tes/etl_worker.py`. Wajib segera dimigrasikan ke variabel lingkungan `.env` sebelum di-push ke GitHub publik.
- `[23-09-2026]` Proyek Flutter di folder `frontend/` belum diinisialisasi (masih kosong menunggu pembuatan backend).

### 🚀 The Next Action
- Inisialisasi repositori Git lokal monorepo dan hubungkan ke GitHub remote.
- Bangun kerangka `backend/` berbasis FastAPI dengan konfigurasi Dockerfile siap deploy ke Hugging Face Spaces.
