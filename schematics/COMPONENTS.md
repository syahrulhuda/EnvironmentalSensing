# Environmental Sensing System (ESS) - Hardware Bill of Materials (BOM)

Dokumen ini memuat daftar inventaris seluruh komponen hardware yang digunakan pada sistem Environmental Sensing System (ESS) berbasis ESP32-C3 SuperMini dan PCB Single-Layer (Revisi `PCB_ESS_5`, 70 mm x 40 mm).

---

## 1. Status Ringkasan Komponen

* **Komponen yang Sudah Tersedia & Teruji Fisik di Breadboard:**
  * Modul ESP32-C3 SuperMini (Teruji flashing & USB CDC COM8)
  * Sensor Suhu & Kelembaban DHT22 (AM2302)
  * Modul Sensor Karbon Monoksida MQ-7 (Teruji baseline 1.25V / ADC 1550)
  * Modul Sensor Asap & Gas Mudah Terbakar MQ-2 (Teruji baseline 0.37V / ADC 460)
  * Modul Display OLED 0.96 inch I2C SSD1306 (Teruji 0x3C, SDA: GPIO8, SCL: GPIO9)
  * LED RGB Common Cathode (Teruji mandiri 4 warna & indikator K3)
  * Komponen Pasif & Filter Daya (C1 Elco 100 µF, C2 Keramik 100 nF, Terminal KF301-2P teruji redam ripple 5.10-5.15V -> 5.13-5.14V)
  * Resistor 220Ω x3, 1kΩ x1, 10kΩ x1 tipe 1/2 Watt, Transistor SS8050, Diode 1N4007
* **Komponen Belum Terpasang / Menunggu Pengiriman:**
  * Kipas DC 5V 4010 (Exhaust Tunnel) & Adaptor 5V 2A Regulated
  * DC-022 Panel Mount Jack, Spacer M3, Baut & Mur akrilik

---

## 2. Rincian Modul & Sensor Utama

| Item | Komponen | Spesifikasi & Deskripsi | Status | Keterangan Pemasangan |
| :--- | :--- | :--- | :--- | :--- |
| **MCU** | **ESP32-C3 SuperMini** | RISC-V 32-bit single-core, WiFi 2.4GHz & BLE, USB-C, 16-pin Through-Hole | **TERUJI FISIK** | Lolos flash Arduino IDE (DIO, CDC Enabled, COM8). Pinout fit PCB |
| **H4** | **Sensor DHT22 (AM2302)** | Sensor suhu (-40 s/d 80 C, presisi 0.5 C) dan kelembaban (0-100% RH, presisi 2-5%) | **TERUJI FISIK** | GPIO 10, pull-up 10k ke 3.3V. Kompensasi TEMP_OFFSET aktif |
| **H1** | **Sensor MQ-7** | Deteksi gas CO (10 - 1000 ppm), modul 4-pin (VCC, GND, DO, AO) | **TERUJI FISIK** | GPIO 1 (ADC1_CH1). Baseline idle stabil di 1.25V (ADC 1550) |
| **H3** | **Sensor MQ-2** | Deteksi LPG, asap, propana, metana, modul 4-pin (VCC, GND, DO, AO) | **TERUJI FISIK** | GPIO 0 (ADC1_CH0). Baseline idle stabil di 0.37V (ADC 460) |
| **H2** | **OLED Display 0.96" I2C** | 128x64 piksel, Driver SSD1306, 4-pin (GND, VCC, SCL, SDA), warna Putih/Biru | **TERUJI FISIK** | Alamat 0x3C, SDA: GPIO8, SCL: GPIO9 dengan timeout anti-freeze |
| **CN1** | **Kipas DC 5V (4010 Fan)** | DC 5V Brushless Fan ukuran 40 x 40 x 10 mm, arus ~0.10 - 0.15 A | **MENUNGGU KIRIMAN** | Menunggu pengiriman untuk uji inrush current & PWM GPIO5 |

---

## 3. Komponen Semikonduktor & Aktif PCB

| Ref Des | Komponen | Spesifikasi Teknis | Footprint / Package | Status | Catatan Khusus |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **D1** | **LED RGB 5mm** | **Common Cathode (CC)** / Katoda Bersama (kaki terpanjang terhubung ke GND), tipe Diffused / Frosted | Through-Hole 4-Pin | **SUDAH ADA** | Disolder langsung di PCB, kepala LED menembus lubang akrilik atas |
| **Q1** | **Transistor NPN** | **SS8050** (arus kolektor 800 mA - 1.5 A), susunan kaki pabrikan **E-B-C** (1=Emitor, 2=Basis, 3=Kolektor) | TO-92 Through-Hole | **SUDAH ADA** | Sesuai footprint PCB. Langsung pasang tanpa silang kaki |
| **D2** | **Diode Flyback** | **1N4007** (1A, 1000V) | DO-41 Through-Hole | **SUDAH ADA** | Proteksi clamp lonjakan induktif motor kipas (Katoda ke +5V, Anoda ke Kolektor Q1) |

---

## 4. Komponen Pasif (Resistor & Kapasitor)

| Ref Des | Komponen | Nilai & Rating | Footprint | Jumlah | Status | Fungsi Rangkaian |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **R1** | Resistor Film | **10 kΩ**, 1/2 Watt (tahan panas) | Axial Through-Hole | 1 pcs | **SUDAH ADA** | Pull-up jalur data DHT22 (GPIO10) |
| **R2** | Resistor Film | **220 Ω**, 1/2 Watt (tahan panas) | Axial Through-Hole | 1 pcs | **SUDAH ADA** | Pembatas arus kanal Merah LED RGB (GPIO4) |
| **R3** | Resistor Film | **220 Ω**, 1/2 Watt (tahan panas) | Axial Through-Hole | 1 pcs | **SUDAH ADA** | Pembatas arus kanal Hijau LED RGB (GPIO3) |
| **R4** | Resistor Film | **220 Ω**, 1/2 Watt (tahan panas) | Axial Through-Hole | 1 pcs | **SUDAH ADA** | Pembatas arus kanal Biru LED RGB (GPIO2) |
| **R5** | Resistor Film | **1 kΩ**, 1/2 Watt (tahan panas) | Axial Through-Hole | 1 pcs | **SUDAH ADA** | Resistor Basis transistor Q1 dari GPIO5 |
| **C1** | Kapasitor Elco | **100 µF / 16V-25V** | Radial Elektrolit (Dia 5mm, Pitch 2.0-2.5mm) | 1 pcs | **SUDAH ADA** | Bulk buffer & peredam ripple daya +5V saat kipas start |
| **C2** | Kapasitor Keramik | **100 nF (0.1 µF)**, kode bodi `104` | Radial Keramik (Pitch 2.5 mm) | 1 pcs | **SUDAH ADA** | Decoupling noise frekuensi tinggi pada rail +5V |

*Catatan:* Resistor 1/2 Watt berdimensi sedikit lebih panjang (~8.5-9mm), pas dengan footprint `R_AXIAL-0.4` (pitch 10.16mm).

---

## 5. Konektor, Terminal, & Socket PCB

| Ref Des | Komponen | Spesifikasi Fisik | Jumlah | Status | Keterangan |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **U1** | **Screw Terminal Block** | **KF301-2P** (Pitch 5.00 mm, 2-pin) | 1 pcs | **SUDAH ADA** | Input daya utama (+5V dan GND) dari panel jack |
| **CN1** | **Konektor JST-XH 2-Pin Siku** | JST-XH 2.54 mm Horizontal / Right-Angle Male Header | 1 pcs | **SUDAH ADA** | Output daya terkontrol untuk Fan 5V (Pin 1=+5V, Pin 2=Kolektor) |
| **H1** | Female Pin Header | 1x4 Pin, Pitch 2.54 mm | 1 pcs | **SUDAH ADA** | Dipotong dari strip Female 1x40 untuk jumper MQ-7 |
| **H2** | Female Pin Header | 1x4 Pin, Pitch 2.54 mm | 1 pcs | **SUDAH ADA** | Dipotong dari strip Female 1x40 untuk jumper OLED I2C |
| **H3** | Female Pin Header | 1x4 Pin, Pitch 2.54 mm | 1 pcs | **SUDAH ADA** | Dipotong dari strip Female 1x40 untuk jumper MQ-2 |
| **H4** | Female Pin Header | 1x3 Pin, Pitch 2.54 mm | 1 pcs | **SUDAH ADA** | Dipotong dari strip Female 1x40 untuk jumper DHT22 |
| **MCU Socket** | Female Pin Header | 2x 1x8 Pin (16 pin total), Pitch 2.54 mm | 2 pcs | **SUDAH ADA** | Dipotong dari strip Female 1x40 untuk dudukan ESP32-C3 SuperMini |

---

## 6. Aksesoris Catu Daya, Mekanikal, & Perkabelan

| Item | Spesifikasi | Jumlah | Status | Fungsi / Alasan Teknis |
| :--- | :--- | :--- | :--- | :--- |
| **Adaptor DC 5V 2A** | Output DC 5.0V regulated, minimal 2.0A, Jack DC 5.5 x 2.1 mm | 1 unit | **PERLU DIBELI** | Pemanas MQ-2 dan MQ-7 masing-masing menarik ~150-180 mA terus-menerus, kipas ~150 mA, WiFi transmisi ~300 mA peak. Adaptor 2A menjamin kestabilan sistem |
| **DC Barrel Jack Panel Mount** | Tipe **DC-022** (ukuran 5.5 x 2.1 mm) model mur/baut | 1 pcs | **PERLU DIBELI** | Dipasang di dinding casing akrilik, kabel dijumper ke terminal KF301 di PCB |
| **Kabel Jumper Female to Female** | Panjang 10 cm atau 20 cm, pitch 2.54 mm | 1 pack (20-40 pin) | **PERLU DIBELI** | Menghubungkan header PCB ke modul sensor yang terpasang pada panel akrilik |
| **Spacer / Standoff PCB M3** | Standoff Nylon atau Kuningan M3 panjang 6 mm atau 10 mm + Baut M3 + Mur | 4 set | **PERLU DIBELI** | Mengunci 4 lubang mounting PCB (diameter lubang 3.2 mm) ke rangka akrilik |

---

## 7. Catatan Teknis Penting Saat Perakitan

1. **Polaritas Soket Kipas (CN1):**
   * Jalur PCB: **Pin 1 = +5V (Kabel Merah)** dan **Pin 2 = Kolektor Transistor / GND Terkontrol (Kabel Hitam)**.
   * Periksa kabel kipas 4010 sebelum dicolok. Jika posisi warna terbalik pada soket female bawaan kipas, congkel kait plastik klip JST dengan pinset/jarum lalu tukar posisi pinnya.
2. **Orientasi Kaki Transistor Q1 (TO-92):**
   * Footprint PCB menggunakan urutan: **Pin 1 = Emitor (GND), Pin 2 = Basis (R5), Pin 3 = Kolektor (CN1)**.
   * Model yang sesuai adalah **SS8050** atau **2N2222**. Jangan menggunakan seri BC547 tanpa memodifikasi silang kaki karena susunannya terbalik.
3. **Orientasi Diode D2 (1N4007):**
   * Gelang putih (Katoda) wajib menghadap ke pin +5V (Pad 1).
   * Kaki tanpa gelang (Anoda) terhubung ke pin Kolektor Q1 (Pad 2).
4. **Orientasi Kapasitor Elco C1 & Hasil Uji Filter:**
   * Garis putih/negatif pada bodi kapasitor wajib menghadap ke Pad bertanda minus / GND (sisi kiri dekat U1).
   * **Hasil Pengujian Empiris Multimeter:** Kombinasi C1 (100 µF) + C2 (100 nF) sukses meredam fluktuasi ripple daya dari `5.10 - 5.15 V` menjadi tegangan stabil `5.13 - 5.14 V` di terminal KF301, serta membuktikan discharging muatan saat catu daya diputus.
5. **Penanganan Flapping USB ESP32-C3 SuperMini (Download Boot Mode):**
   * Jika board mengalami *flapping* (putus-nyambung USB berulang saat pertama dicolok ke PC): **Tahan tombol BOOT, tekan tombol RST sekali, lalu lepas tombol BOOT**.
   * SoC ESP32-C3 akan mengunci ke mode download boot, menstabilkan port COM (misal: COM8) di Device Manager.
   * Parameter wajib di Arduino IDE: Board `ESP32C3 Dev Module`, **Flash Mode: `DIO`** (bukan QIO), dan **USB CDC On Boot: `Enabled`**.
6. **Mitigasi Thermal Cross-Heating (Jarak Fisik DHT22 dan Sensor MQ):**
   * Sensor MQ-2 dan MQ-7 memiliki kumparan pemanas internal (*heater coil*) yang membuang daya panas gabungan ~1.5 Watt ke lingkungan sekitar (suhu permukaan MQ mencapai 45 - 55 C).
   * Pada enclosure fisik / intake tunnel, berikan jarak pemisah minimal 2 - 3 cm antara DHT22 dan kedua sensor MQ agar pembacaan suhu DHT22 tidak terdistorsi oleh mikroklimat panas sensor gas. Gunakan kompensasi firmware `#define TEMP_OFFSET` jika terdapat deviasi suhu konstan.
