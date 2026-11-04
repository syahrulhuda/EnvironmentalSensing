# 📐 Panduan Teknis Desain Akrilik 2D (Laser Cutting Ready)
**Smart Environmental Sensing System (ESS)**  
*Laboratorium & Bengkel Teknik Mekatronika, Politeknik Kota Malang (POLTEKOM)*

Dokumen ini memuat detail dimensi, penjelasan teknis penempatan sensor, dan instruksi perakitan untuk **2 Desain Akrilik 2D (Tebal 3 mm)** menggunakan sistem **Tab & Slot Clamping dengan Corner Standoff (Tiang Spacer Baut)** sesuai model knock-down yang telah diselaraskan **100% presisi dengan file JSON & Layout EasyEDA PCB v5**, foto fisik modul sensor, dan revisi kipas 3x3 cm.

---

## 📂 File Vektor 2D Siap Potong Laser (Tersedia di `/schematics`)
File vektor berformat `.SVG` telah diperbarui dan disimpan di folder proyek lokal serta di folder [`/schematics`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics):
1. **Desain 1 (Tunnel Sensor MQ-2 & MQ-7 Offset Asimetris + Fan 30x30 mm):**  
   👉 [`laser_cutting_tunnel_sensor.svg`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/laser_cutting_tunnel_sensor.svg)
2. **Desain 2 (Case PCB Alat - Clearance 1 cm Kiri-Kanan + Port Lengkap):**  
   👉 [`laser_cutting_case_pcb.svg`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/laser_cutting_case_pcb.## 🔬 Hasil Verifikasi Detail Foto Fisik & Pengukuran Sensor
### 1. Orientasi Tegak Modul Sensor MQ-2 & MQ-7 (Ukuran Custom Sesuai Pengukuran Fisik)
Berdasarkan pengukuran fisik modul aktual yang digunakan:
* **Data Dimensi Fisik Modul Sensor:**
  * **Modul MQ-2:** Menggunakan lubang tembus diameter **$\varnothing 20,5\text{ mm}$** (jari-jari $10,25\text{ mm}$), pas melingkupi ring flens/bodi dasar sensor MQ-2.
  * **Modul MQ-7:** Menggunakan lubang tembus diameter **$\varnothing 18,4\text{ mm}$** (jari-jari $9,20\text{ mm}$), pas melingkupi tutup tabung silinder abu-abu (*grey cap*) sensor MQ-7.
* **Titik Pusat Sensor & Analisis Jarak Bebas (Anti-Tabrakan):**
  * Kedua sensor diposisikan sejajar di garis horizontal **$Y = 27,0\text{ mm}$** (di paruh bawah PCB tegak):
    * **MQ-2 ($\varnothing 20,5\text{ mm}$ di $X = 40,0\text{ mm}, Y = 27,0\text{ mm}$):**
      * Ke 2 baut bawah ($Y = 38,25\text{ mm}$): Jarak diagonal $= 13,52\text{ mm}$, menyisakan daging akrilik solid selebar **$1,87\text{ mm}$** (**100% BEBAS TABRAKAN!**).
      * Ke 2 baut atas ($Y = 11,75\text{ mm}$): Jarak diagonal $= 17,00\text{ mm}$, menyisakan daging akrilik solid selebar **$5,34\text{ mm}$**.
    * **MQ-7 ($\varnothing 18,4\text{ mm}$ di $X = 78,0\text{ mm}, Y = 27,0\text{ mm}$):**
      * Ke 2 baut bawah ($Y = 38,25\text{ mm}$): Jarak diagonal $= 13,52\text{ mm}$, menyisakan daging akrilik solid selebar **$2,92\text{ mm}$** (**100% BEBAS TABRAKAN!**).
      * Ke 2 baut atas ($Y = 11,75\text{ mm}$): Jarak diagonal $= 17,00\text{ mm}$, menyisakan daging akrilik solid selebar **$6,39\text{ mm}$**.
* **4 Lubang Baut Pengunci (Pitch $15,0\text{ mm} \times 26,5\text{ mm}$):**
  * Di sumbu horizontal (X): Pitch $15,0\text{ mm}$ ($X = 32,5$ dan $X = 47,5\text{ mm}$ untuk MQ-2; $X = 70,5$ dan $X = 85,5\text{ mm}$ untuk MQ-7).
  * Di sumbu vertikal (Y): Pitch $26,5\text{ mm}$ ($Y = 11,75\text{ mm}$ untuk 2 baut atas, dan $Y = 38,25\text{ mm}$ untuk 2 baut bawah).

---

### 2. Koreksi Lubang Kipas 3x3 cm (Fan 3010)
* **Diameter Lubang Angin Kipas:** Disesuaikan menjadi **$\varnothing 22,0\text{ mm}$** (jari-jari $11,0\text{ mm}$):
  * Sesuai dengan diameter bilah sudu impeller kipas $30 \times 30\text{ mm}$.
  * Memberikan jarak aman **$\approx 5,97\text{ mm}$** ke 4 lubang baut sudut M3 (pitch $24,0 \times 24,0\text{ mm}$), sehingga dinding akrilik penahan baut jauh lebih kokoh dan tidak mudah retak.

---

## 🌪️ Rincian Desain 1: Tunnel Sensor Gas (Update V5 - MQ-2 Dia 20.5 mm & MQ-7 Dia 18.4 mm)
File: [`laser_cutting_tunnel_sensor.svg`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/laser_cutting_tunnel_sensor.svg)

1. **Pelat Atas (Dudukan Tegak Sensor MQ-2 & MQ-7 - $120 \times 50\text{ mm}$):**
   * **Sensor MQ-2 (Tegak: $20 \times 32\text{ mm}$ di $X = 30..50\text{ mm}$):**
     * Pin Header: di sisi atas ($Y = 9,0\text{ mm}$).
     * Lubang tembus bodi filter: **$\varnothing 20,5\text{ mm}$** di **$X = 40,0\text{ mm}, Y = 27,0\text{ mm}$** (di paruh bawah).
     * 2 Baut Atas: $X = 32,5\text{ mm}$ dan $X = 47,5\text{ mm}$ ($Y = 11,75\text{ mm}$).
     * 2 Baut Bawah: $X = 32,5\text{ mm}$ dan $X = 47,5\text{ mm}$ ($Y = 38,25\text{ mm}$).
   * **Sensor MQ-7 (Tegak: $20 \times 32\text{ mm}$ di $X = 68..88\text{ mm}$):**
     * Pin Header: di sisi atas ($Y = 9,0\text{ mm}$).
     * Lubang tembus bodi filter: **$\varnothing 18,4\text{ mm}$** di **$X = 78,0\text{ mm}, Y = 27,0\text{ mm}$** (di paruh bawah).
     * 2 Baut Atas: $X = 70,5\text{ mm}$ dan $X = 85,5\text{ mm}$ ($Y = 11,75\text{ mm}$).
     * 2 Baut Bawah: $X = 70,5\text{ mm}$ dan $X = 85,5\text{ mm}$ ($Y = 38,25\text{ mm}$).
   * Jarak renggang antar kedua modul MQ: **$18,0\text{ mm}$** (sangat leluasa).** (sangat leluasa).
2. **Pelat Outlet Belakang / Tatakan Kipas 3x3 cm ($44 \times 44\text{ mm}$):**
   * Lubang hembusan angin tengah: $\varnothing 22,0\text{ mm}$.
   * 4 Lubang baut kipas pitch $24,0 \times 24,0\text{ mm}$ ($\varnothing 3,2\text{ mm}$ untuk baut M3).
3. **Pelat Inlet Depan ($44 \times 44\text{ mm}$):**
   * 1 Lubang lingkaran tunggal $\varnothing 22\text{ mm}$ di tengah untuk jaring kawat.
   * Terpasang di slot $X = 12,0\text{ mm}$ (di sebelah dalam dari tiang spacer depan).
4. **Pelat Dinding Samping Kiri & Kanan (Panjang Disesuaikan Tepat $93 \times 44\text{ mm}$):**
   * **Bebas Tabrakan Spacer:** Panjang dinding dipotong menjadi **$93,0\text{ mm}$** (membentang tepat di antara Inlet Depan di $X = 12\text{ mm}$ dan Outlet Belakang di $X = 105\text{ mm}$).
   * 4 Tiang spacer M3 di pojok ($X = 5,5\text{ mm}$ dan $X = 114,5\text{ mm}$) berdiri bebas di luar ruangan tunnel mengklem pelat atas dan bawah dengan kokoh.

---

## 📦 Rincian Desain 2: Case PCB Alat (5 Bagian - Duduk Langsung di Atas Pelat Tunnel Tanpa Pelat Bawah)
File DXF: Folder [`/schematics/dxf`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/dxf) & [`laser_cutting_case_pcb.svg`](file:///D:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/laser_cutting_case_pcb.svg)

> [!NOTE]
> **Konsep Tanpa Pelat Bawah Sendiri:** Case PCB alat tidak memerlukan pelat alas akrilik ganda. Pelat atas tunnel sensor ($120 \times 50\text{ mm}$) berfungsi ganda sebagai lantai bersama. Seluruh dinding samping case mengunci langsung ke slot pelat tunnel, dan PCB ESS 5 ditopang spacer $2,5\text{ cm}$ mengambang di atas sensor MQ.

1. **Pelat Tutup Atas ($114,0 \times 50,0\text{ mm}$):**
   * 4 Lubang Tiang Spacer M3 sudut (pitch $103,0 \times 39,0\text{ mm}$) mengunci ke pelat atas tunnel.
   * 4 Slot Purus dinding $20,0 \times 3,1\text{ mm}$ (Kiri, Kanan, Depan, Belakang).
   * Dudukan Layar OLED 0.96": Jendela $24,0 \times 13,0\text{ mm}$ + 4 baut M2 pitch $23,3 \times 23,3\text{ mm}$.
   * Lubang LED RGB D1 (Dia 5.5 mm): Di paruh atas ($X = 62,64\text{ mm}, Y = 35,61\text{ mm}$) sejajar vertikal footprint D1 PCB.
   * 4 Baris Celah Ventilasi Tengah ($12,0 \times 2,0\text{ mm}$) di antara OLED dan DHT22.
   * Jendela DHT22 Bodi Putih ($15,5 \times 25,5\text{ mm}$) & **Baut Pengunci M3 di BAWAH** ($X = 83,75\text{ mm}, Y = 8,50\text{ mm}$).

2. **Dinding Sisi Kiri (Panel Port USB Type-C ESP32 - $40,0 \times 46,0\text{ mm}$):**
   * Bodi $40,0 \times 40,0\text{ mm}$ dengan purus atas dan bawah ($20,0 \times 3,0\text{ mm}$).
   * Lubang colokan USB Type-C berukuran $14,0 \times 8,0\text{ mm}$ presisi di ketinggian soket ESP32-C3.

3. **Dinding Sisi Kanan (Panel Daya DC Barrel Jack DC-022 - $40,0 \times 46,0\text{ mm}$):**
   * Bodi $40,0 \times 40,0\text{ mm}$ dengan purus atas dan bawah ($20,0 \times 3,0\text{ mm}$).
   * **Lubang Dudukan Soket DC-022:** Lingkaran presisi **$\varnothing 12,0\text{ mm}$** di titik tengah ($X = 20,0\text{ mm}, Y = 23,0\text{ mm}$) untuk memasang soket DC barrel jack $5,5 \times 2,1\text{ mm}$ panel mount berpengunci mur heksagonal M12.
   * 2 Celah ventilasi horizontal di atas dan di bawah soket ($18,0 \times 2,0\text{ mm}$).

4. **Dinding Sisi Depan (Muka Boks - $96,0 \times 46,0\text{ mm}$):**
   * Bodi $96,0 \times 40,0\text{ mm}$ dengan purus atas dan bawah ($20,0 \times 3,0\text{ mm}$ di $X = 38,0 - 58,0\text{ mm}$).
   * 3 Baris kisi ventilasi estetis bertingkat ($56, 46, 36\text{ mm}$).

5. **Dinding Sisi Belakang (Panel Kisi Ventilasi Penuh - $96,0 \times 46,0\text{ mm}$):**
   * Bodi $96,0 \times 40,0\text{ mm}$ dengan purus atas dan bawah ($20,0 \times 3,0\text{ mm}$ di $X = 38,0 - 58,0\text{ mm}$).
   * **Bebas Lubang Kabel Liar:** Lubang kabel eksternal dan zip-tie telah dihilangkan karena seluruh kabel jumper MQ & fan melintas internal langsung ke tunnel.
   * Digantikan dengan **3 baris kisi ventilasi estetis bertingkat** ($56, 46, 36\text{ mm}$) sama persis dengan dinding depan sehingga boks tampil simetris dan rapi.

## 🛠️ Daftar Kebutuhan Hardware Perakitan

| No | Komponen Hardware | Ukuran Standar | Jumlah | Keterangan |
| :---: | :--- | :--- | :---: | :--- |
| 1 | **Lembar Akrilik Bening (Clear)** | Tebal **3.0 mm** | $\approx 35 \times 30\text{ cm}$ | Untuk kedua pola SVG |
| 2 | **Tiang Spacer M3 (Hex Standoff)** | **Tinggi 38-40 mm** (Tunnel)<br>**Tinggi 35-40 mm** (Case PCB) | **8 pcs total** | 4 pcs untuk Tunnel, 4 pcs untuk Box PCB |
| 3 | **Baut M3 Kepala Bulat / Payung** | **M3 $\times$ 6 mm** | **16 pcs** | Pengunci tiang spacer sudut atas & bawah |
| 4 | **Baut Kipas 3x3 cm** | **M3 $\times$ 12 mm atau 15 mm + Mur** | **4 pasang** | Pengunci kipas 30x30 mm ke pelat outlet |
| 5 | **Baut Modul Sensor MQ-2 & MQ-7** | **M2 atau M2.5 $\times$ 8 mm + Mur** | **8 pasang** | 4 baut untuk MQ-2, 4 baut untuk MQ-7 |
| 6 | **Baut Modul LCD OLED 0.96" I2C** | **M2 $\times$ 8 mm atau 10 mm + Mur** | **4 pasang** | Pengunci 4 sudut modul OLED ke pelat atas |
| 7 | **Baut Modul DHT22 3-Pin** | **M3 $\times$ 8 mm atau 10 mm + Mur** | **1 pasang** | Pengunci 1 lubang baut modul DHT22 ke pelat atas |
| 8 | **Spacer Dudukan PCB Pendek** | **M3 Tinggi 6 mm (Male-Female)** | **4 pcs** | Pengganjal bawah PCB ke lantai akrilik |
| 9 | **Kipas DC 5V (3010 Fan)** | **30 $\times$ 30 $\times$ 10 mm** | **1 unit** | Kipas hisap exhaust tunnel |
| 10 | **Jaring Kawat / Kasa Halus** | Potongan $\approx 3 \times 3\text{ cm}$ | **1 pcs** | Ditempel di lubang inlet lingkaran tunnel |

---

## 💡 Petunjuk Cetak Laser:
1. **Garis Merah:** Garis potong tembus (*Cut*), tebal hairline $0,2\text{ mm}$.
2. **Garis Biru / Putus-putus:** Garis grafir penanda posisi (*Engrave*).
3. **Teks Label:** Hanya panduan pembacaan dimensi visual, tidak perlu digrafir pada akrilik.
