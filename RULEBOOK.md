# 📜 RULEBOOK (The Constitution of Environmental Sensing)

Dokumen ini adalah konstitusi dan aturan main tertinggi dalam pengembangan sistem **Smart Environmental Sensing System (ESS)** (Bengkel Mekatronika POLTEKOM). Setiap kontributor (baik programmer manusia maupun asisten AI) **WAJIB** mematuhi 6 pilar di bawah ini.

---

## 🏛️ Pilar 1: Filosofi Pengembangan
1. **Safety & ESS-First Mindset:** Keakuratan data sensor gas beracun (CO / MQ-7) dan asap/fume (MQ-2) menyangkut keselamatan nyawa teknisi di bengkel. Jangan pernah memanipulasi atau menyembunyikan lonjakan (*peak spikes*) anomali bahaya demi estetika grafik.
2. **Pragmatism over Perfection:** Lebih baik sistem berjalan stabil, teruji di hardware fisik, dan tercatat di `WHITEBOARD.md`, daripada mengejar kesempurnaan teori tetapi tidak pernah selesai diuji di lapangan.
3. **Decoupled Architecture:** Setiap layer (`hardware/`, `backend/`, `frontend/`) harus berdiri sendiri tanpa ketergantungan erat (*tight coupling*). Rusaknya satu komponen tidak boleh merobohkan keseluruhan sistem.

---

## 🌿 Pilar 2: Aturan Manajemen Versi
*(SANGAT KETAT: Komit yang tidak rapi wajib disusun ulang)*
1. **Atomic Commits:** Lakukan commit untuk satu tujuan logis yang terisolasi. Jangan campur aduk perubahan hardware dengan perubahan backend dalam satu commit.
2. **Conventional Commits:** Penamaan commit wajib mengikuti standar industri:
   - `feat:` Penambahan fitur baru (misal: penambahan endpoint chat Gemini, pembuatan widget gauge Flutter).
   - `fix:` Perbaikan bug (misal: perbaikan drift ADC MQ-7, perbaikan CORS FastAPI).
   - `docs:` Perubahan murni pada dokumentasi (`README.md`, `WHITEBOARD.md`).
   - `refactor:` Restrukturisasi kode tanpa mengubah fungsionalitas.
   - `chore:` Pembaruan dependensi, konfigurasi build, atau file `.gitignore`.
3. **Descriptive Commit Message:** Berikan penjelasan singkat namun padat pada judul commit, serta sertakan bullet point jika melibatkan perubahan penting.

---

## 💻 Pilar 3: Standar Penulisan Kode
1. **Hardware (C++ / PlatformIO / Arduino):**
   - **Dilarang keras memakai `delay()`** di dalam fungsi `loop()`. Wajib menggunakan non-blocking timer berbasis `millis()`.
   - Pisahkan logika menjadi fungsi-fungsi modular (sensor reading, display, telemetri HTTPS).
2. **Backend (Python & FastAPI):**
   - Wajib menyertakan *type hints* standar Python.
   - Tangani error secara eksplisit (*try-except* dengan logging jelas; dilarang menggunakan *silent pass*).
   - Logika ETL wajib idempotent: gunakan `ON CONFLICT (device_id, recorded_at) DO UPDATE / DO NOTHING` saat menyimpan ke database relasional.
3. **Frontend (Flutter & Dart):**
   - Utamakan *StatelessWidget* dan pemisahan komponen modular. Dilarang membuat satu file UI raksasa monolitik (> 250 baris).
   - Gunakan layout responsif yang adaptif terhadap layar Web (desktop) dan Mobile (smartphone).

---

## 📚 Pilar 4: Aturan Dokumentasi
Setiap file dokumentasi memiliki tanggung jawab spesifik dan tidak boleh saling tumpang tindih:
1. `README.md` = **Wajah Proyek.** Dokumentasi publik, gambaran umum arsitektur 5-Layer, panduan setup, dan spesifikasi sistem.
2. `WHITEBOARD.md` = **Dapur Kotor.** Dokumen kerja aktif untuk mencatat fokus saat ini (*Grand Plan*), log arsip ide (*Ideas Log*), dan audit berkala (*The Ruthless Audit*).
3. `RULEBOOK.md` = **Kitab Hukum.** Dokumen ini. Tempat di mana seluruh standar teknis dan batasan arsitektur disepakati.

---

## 🔒 Pilar 5: Aturan Keamanan & Kredensial
1. **Zero Hardcoded Secrets:** DILARANG KERAS menuliskan API Key Gemini, Service Role Key Supabase, maupun Firebase Private Key langsung di dalam file kode sumber publik.
2. **Environment Variables:** Semua kredensial wajib dibaca melalui variabel lingkungan (`.env` di backend) dan hanya file `.env.example` yang boleh di-commit ke Git.
3. **Client-Side Protection:** Aplikasi frontend (Flutter) tidak boleh memegang kredensial admin database. Seluruh interaksi AI dan database historis wajib melalui backend API (FastAPI Gateway).

---

## 🚀 Pilar 6: Standar Otomasi & CI/CD (Zero-Manual-Ops)
1. **Automated Web Deployment:** Seluruh rilis antarmuka Web Dashboard ke Firebase Hosting (`poltekom-ess.web.app`) dieksekusi secara otomatis oleh GitHub Actions (`.github/workflows/deploy-web.yml`) pada setiap `push` ke branch `main`. Dilarang melakukan kompilasi atau deployment hosting manual secara ad-hoc dari workstation lokal untuk lingkungan produksi.
2. **Secure CI/CD Credential Management:**
   - Kredensial Google Service Account disimpan secara terenkripsi di GitHub Repository Secrets (`FIREBASE_SERVICE_ACCOUNT`).
   - Dilarang memanggil context `secrets` di dalam ekspresi conditional `if:` pada workflow schema GitHub Actions.
   - Kredensial diinjeksi melalui environment variable runner dan ditulis ke berkas sementara di dalam `$RUNNER_TEMP`, yang wajib langsung dihapus (`rm -f`) setelah proses deployment selesai.
3. **Explicit Project & Site Scoping:** Setiap eksekusi deploy hosting wajib menyertakan target project (`environmental-sensing-f6e1c`) dan mengacu pada konfigurasi multi-site `firebase.json` (`site: poltekom-ess`) untuk mencegah salah sasaran hosting.
4. **Resilient Edge & Mobile Delivery:** Pembaruan backend Raspberry Pi wajib diarahkan melalui self-hosted runner terisolasi, dan distribusi APK mobile wajib melalui automated tagged release (`v*`) dengan verifikasi integritas in-app OTA.
