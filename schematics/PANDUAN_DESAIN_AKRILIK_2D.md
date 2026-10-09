# 📐 Panduan Teknis Desain Akrilik 2D (Laser Cutting Ready)
**Smart Environmental Sensing System (ESS)**  
*Laboratorium & Bengkel Teknik Mekatronika, Politeknik Kota Malang (POLTEKOM)*

Dokumen ini memuat detail dimensi, penjelasan teknis penempatan sensor, dan instruksi perakitan untuk **2 Desain Akrilik 2D (Tebal 3 mm)** menggunakan sistem **Tab & Slot Clamping dengan Corner Standoff (Tiang Spacer Baut)** sesuai model knock-down yang telah diselaraskan **100% presisi dengan file JSON & Layout EasyEDA PCB v5** serta permintaan clearance dari tim.

---

## 📂 File Vektor 2D Siap Potong Laser (Tersedia di `/schematics`)
File vektor berformat `.SVG` telah diperbarui dan disimpan di folder proyek lokal serta di folder [`/schematics`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics):
1. **Desain 1 (Tunnel Sensor Khusus MQ-2 & MQ-7 + Fan 4x4 cm):**  
   👉 [`laser_cutting_tunnel_sensor.svg`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/laser_cutting_tunnel_sensor.svg)
2. **Desain 2 (Case PCB Alat - Clearance 1 cm Kiri-Kanan + Port Lengkap):**  
   👉 [`laser_cutting_case_pcb.svg`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/laser_cutting_case_pcb.svg)

---

## 🔍 Data Presisi PCB & Penyesuaian Ruang (Clearance 1 cm)

| Parameter | Nilai Fisik PCB EasyEDA | Dimensi Akrilik | Keterangan & Fungsi |
| :--- | :---: | :---: | :--- |
| **Ukuran PCB** | **$70,00 \times 40,00\text{ mm}$** | Ruang dalam: **$90 \times 60\text{ mm}$** | Memberikan **space tepat $1,0\text{ cm}$ ($10\text{ mm}$)** di sisi kiri dan kanan |
| **Dimensi Luar Case** | - | **$96,00 \times 66,00 \times 45,00\text{ mm}$** | Tebal akrilik $3,0\text{ mm}$ |
| **Pitch Baut Dudukan PCB** | **$64,40 \times 34,40\text{ mm}$** | Slot toleransi $3,5 \times 3,5\text{ mm}$ | Margin dari tepi PCB tepat $2,80\text{ mm}$ |
| **Panel Dinding Kiri** | Port USB Type-C ESP32 | Celah lubang $16 \times 9\text{ mm}$ | Center $X = 33\text{ mm}$, leluasa untuk kepala kabel USB-C |
| **Panel Dinding Kanan (1)**| Screw Terminal KF301 | Celah lubang $13 \times 9,5\text{ mm}$ | Input power 5V & akses obeng terminal |
| **Panel Dinding Kanan (2)**| Soket Kipas CN1 (JST-XH) | Celah lubang $12 \times 9\text{ mm}$ | Colokan soket kabel kipas DC 5V menuju tunnel |
| **Panel Dinding Belakang**| Header MQ-7 & MQ-2 | Celah kabel $28 \times 10\text{ mm}$ + 2 zip-tie | Jalur lurus kabel sensor gas menuju tabung tunnel |
| **Pelat Atas (Top Cover)** | Dudukan DHT22 & LED RGB | Celah DHT22 $16 \times 22\text{ mm}$ + lubang LED $\varnothing 6\text{ mm}$| Kabel DHT22 langsung turun ke H4, LED RGB terlihat jelas |

---

## 📦 Rincian Desain 2: Case PCB Alat

### A. Dimensi & Ruang Bebas (Clearance 1 cm)
* **Ukuran Luar Case:** **$96\text{ mm} \times 66\text{ mm} \times 45\text{ mm}$**
* **Ruang Dalam:** $90\text{ mm} \times 60\text{ mm}$.
  * Karena PCB berukuran $70 \times 40\text{ mm}$, terdapat ruang kosong:
    * Sisi Kiri: **$10\text{ mm}$ ($1,0\text{ cm}$)**
    * Sisi Kanan: **$10\text{ mm}$ ($1,0\text{ cm}$)**
    * Sisi Depan & Belakang: **$10\text{ mm}$ ($1,0\text{ cm}$)**
  * Space ini menjamin kepala kabel USB-C leluasa menancap, serta kabel adaptor daya dan soket kipas tidak tertekuk tajam.

### B. Dinding Sisi Kiri (Panel USB ESP32-C3 SuperMini)
* Diberi bukaan rounded rectangle **$16 \times 9\text{ mm}$** tepat di posisi tengah ($X = 33\text{ mm}$ pada pelat $66\text{ mm}$).
* Kabel USB-C tipe apa pun (termasuk model tebal/braided) dapat dicolok langsung dari luar casing untuk update/flash firmware ESP32 tanpa membuka baut casing.

### C. Dinding Sisi Kanan (Screw Terminal & Soket Kipas CN1)
Disediakan **2 lubang bukaan terpisah**:
1. **Lubang Screw Terminal KF301 (Input Daya 5V):** Ukuran $13 \times 9,5\text{ mm}$ di posisi $X = 25\text{ mm}$. Memudahkan memasukkan kabel adaptor $5\text{V}$ dan menjangkau baut terminal dengan obeng kecil.
2. **Lubang Soket Kipas CN1 (JST-XH 2.54 Siku):** Ukuran $12 \times 9\text{ mm}$ di posisi $X = 42\text{ mm}$. Soket kipas $5\text{V}$ dapat langsung dicolok dari luar menuju tunnel sensor.
3. Di antara kedua lubang tersebut terdapat jembatan akrilik selebar $5\text{ mm}$ yang kokoh dan tidak lentur.

### D. Dinding Sisi Belakang (Keluaran Kabel ke Tunnel Sensor Gas)
* Celah kabel selebar **$28\text{ mm}$** tinggi **$10\text{ mm}$** diletakkan tepat di depan Header MQ-7 ($X=26\text{ mm}$) dan Header MQ-2 ($X=42\text{ mm}$).
* Dilengkapi 2 lubang baut/tali ties ($\varnothing 3,0\text{ mm}$) untuk menjepit bundel kabel agar rapi dan tidak mudah tertarik.

### E. Pelat Atas (Top Cover)
1. **Dudukan Sensor DHT22:**
   * Celah kepala kisi probe DHT22 ($16 \times 22\text{ mm}$) + lubang baut M3 diletakkan tepat di atas Header H4 ($X \approx 48\text{ mm}, Y \approx 40\text{ mm}$).
   * Kabel modul DHT22 dari atas langsung meluncur vertikal ke bawah menancap ke Header H4 tanpa kusut.
2. **Lubang Intip LED RGB (D1):**
   * Lubang bundar $\varnothing 6,0\text{ mm}$ tepat di atas LED RGB D1 agar pendaran status sistem (Aman, Waspada, Bahaya) terlihat jelas dari atas.

### F. Pelat Bawah (Bottom Base)
1. Garis grafir putus-putus kotak PCB $70 \times 40\text{ mm}$ tepat di tengah ($X = 13$ s/d $83\text{ mm}$, $Y = 13$ s/d $53\text{ mm}$).
2. 4 Lubang dudukan baut PCB dengan jarak pitch presisi **$64,40 \times 34,40\text{ mm}$** dengan toleransi slot oval $3,5\text{ mm}$.

---

## 🌪️ Rincian Desain 1: Tunnel Sensor Gas
File: [`laser_cutting_tunnel_sensor.svg`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/laser_cutting_tunnel_sensor.svg)
* **Dimensi Luar:** $120 \times 50 \times 50\text{ mm}$ (panjang kompak $12\text{ cm}$).
* **Sensor di Dalam:** Khusus **MQ-2** dan **MQ-7** (lubang kubah diameter $\varnothing 20\text{ mm}$).
* **Inlet Depan:** 1 Lubang lingkaran tunggal $\varnothing 22\text{ mm}$ di tengah (seukuran uang koin), siap dipasangi kasa / jaring kawat sendiri dari sisi dalam.
* **Outlet Belakang:** Dudukan Kipas Hisap DC 40x40 mm (lubang hembusan $\varnothing 36\text{ mm}$, 4 lubang baut M3 pitch simetris $32 \times 32\text{ mm}$).
* **Kaki Dudukan Penopang (Pelat 7):** Sepasang bracket opsional jika tunnel ingin dibaut mati ke meja laboratorium / testing rig.

---

## 🛠️ Daftar Kebutuhan Hardware Perakitan

| No | Komponen Hardware | Ukuran Standar | Jumlah | Keterangan |
| :---: | :--- | :--- | :---: | :--- |
| 1 | **Lembar Akrilik Bening (Clear)** | Tebal **3.0 mm** | $\approx 35 \times 30\text{ cm}$ | Untuk kedua pola SVG |
| 2 | **Tiang Spacer M3 (Hex Standoff)** | **Tinggi 44-50 mm** (Tunnel)<br>**Tinggi 40 mm** (Case PCB) | **8 pcs total** | 4 pcs untuk Tunnel, 4 pcs untuk Box PCB |
| 3 | **Baut M3 Kepala Bulat / Payung** | **M3 $\times$ 6 mm** | **16 pcs** | Pengunci tiang spacer sudut atas & bawah |
| 4 | **Spacer Dudukan PCB Pendek** | **M3 Tinggi 6 mm (Male-Female)** | **4 pcs** | Pengganjal bawah PCB ke lantai akrilik |
| 5 | **Baut Kipas 4x4 cm** | **M3 $\times$ 15 mm + Mur M3** | **4 pasang** | Pengunci kipas ke pelat outlet |
| 6 | **Kipas DC 5V (4010 Fan)** | **40 $\times$ 40 $\times$ 10 mm** | **1 unit** | Kipas hisap exhaust tunnel |
| 7 | **Jaring Kawat / Kasa Halus** | Potongan $\approx 3 \times 3\text{ cm}$ | **1 pcs** | Ditempel di lubang inlet lingkaran tunnel |

---

## 💡 Petunjuk Cetak Laser:
1. **Garis Merah:** Garis potong tembus (*Cut*), tebal hairline $0,2\text{ mm}$.
2. **Garis Biru / Putus-putus:** Garis grafir penanda posisi (*Engrave*).
3. **Teks Label:** Hanya panduan pembacaan dimensi visual, tidak perlu digrafir pada akrilik.
