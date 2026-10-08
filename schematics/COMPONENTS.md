# Environmental Sensing System (ESS) - Hardware Bill of Materials (BOM)

Dokumen ini memuat daftar inventaris seluruh komponen hardware yang digunakan pada sistem Environmental Sensing System (ESS) berbasis ESP32-C3 SuperMini dan PCB Single-Layer (Revisi `PCB_ESS_5`, 70 mm x 40 mm).

---

## 1. Status Ringkasan Komponen

* **Komponen yang Sudah Tersedia:**
  * Modul ESP32-C3 SuperMini
  * Sensor Suhu & Kelembaban DHT22 (AM2302)
  * Modul Sensor Karbon Monoksida MQ-7
  * Modul Sensor Asap & Gas Mudah Terbakar MQ-2
* **Komponen yang Perlu Dibeli:**
  * Modul Display OLED 0.96 inch I2C (SSD1306)
  * DC Brushless Fan 5V 4010 (Exhaust / Intake Tunnel)
  * Komponen Semikonduktor (LED RGB Common Cathode, Transistor NPN SS8050/2N2222, Diode 1N4007)
  * Komponen Pasif (Resistor 220 ohm, 1k ohm, 10k ohm, Kapasitor Elco 100 uF, Kapasitor Keramik 100 nF)
  * Konektor & Terminal PCB (KF301-2P, JST-XH 2-Pin Siku, Female Pin Header 2.54 mm)
  * Aksesoris Enclosure & Catu Daya (Adaptor 5V 2A, DC-022 Panel Mount, Spacer M3, Kabel Jumper)

---

## 2. Rincian Modul & Sensor Utama

| Item | Komponen | Spesifikasi & Deskripsi | Status | Keterangan Pemasangan |
| :--- | :--- | :--- | :--- | :--- |
| **MCU** | **ESP32-C3 SuperMini** | RISC-V 32-bit single-core, WiFi 2.4GHz & BLE, USB-C, 16-pin Through-Hole | **SUDAH ADA** | Dipasang ke socket Female Header 2x8 pin di PCB |
| **H4** | **Sensor DHT22 (AM2302)** | Sensor suhu (-40 s/d 80 C, presisi 0.5 C) dan kelembaban (0-100% RH, presisi 2-5%) | **SUDAH ADA** | Panel mount intake tunnel, koneksi jumper ke header H4 |
| **H1** | **Sensor MQ-7** | Deteksi gas CO (10 - 1000 ppm), modul 4-pin (VCC, GND, DO, AO) | **SUDAH ADA** | Panel mount tunnel, koneksi jumper ke header H1 |
| **H3** | **Sensor MQ-2** | Deteksi LPG, asap, propana, metana, modul 4-pin (VCC, GND, DO, AO) | **SUDAH ADA** | Panel mount tunnel, koneksi jumper ke header H3 |
| **H2** | **OLED Display 0.96" I2C** | 128x64 piksel, Driver SSD1306, 4-pin (GND, VCC, SCL, SDA), warna Putih/Biru | **PERLU DIBELI** | Panel mount casing depan, koneksi jumper ke header H2 |
| **CN1** | **Kipas DC 5V (4010 Fan)** | DC 5V Brushless Fan ukuran 40 x 40 x 10 mm, arus ~0.10 - 0.15 A | **PERLU DIBELI** | Dipasang di exhaust tunnel, kabel konektor colok ke CN1 |

---

## 3. Komponen Semikonduktor & Aktif PCB

| Ref Des | Komponen | Spesifikasi Teknis | Footprint / Package | Status | Catatan Khusus |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **D1** | **LED RGB 5mm** | **Common Cathode (CC)** / Katoda Bersama (kaki terpanjang terhubung ke GND), tipe Diffused / Frosted | Through-Hole 4-Pin | **PERLU DIBELI** | Disolder langsung di PCB, kepala LED menembus lubang akrilik atas |
| **Q1** | **Transistor NPN** | **SS8050** atau **2N2222** (arus kolektor 800 mA - 1.5 A), susunan kaki **E-B-C** (1=Emitor, 2=Basis, 3=Kolektor) | TO-92 Through-Hole | **PERLU DIBELI** | Saklar low-side driver kipas. Hindari BC547 karena kaki C-B-E terbalik |
| **D2** | **Diode Flyback** | **1N4007** (1A, 1000V) atau 1N4001 - 1N4004 | DO-41 Through-Hole | **PERLU DIBELI** | Proteksi clamp lonjakan induktif motor kipas (Katoda ke +5V, Anoda ke Kolektor Q1) |

---

## 4. Komponen Pasif (Resistor & Kapasitor)

| Ref Des | Komponen | Nilai & Rating | Footprint | Jumlah | Status | Fungsi Rangkaian |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **R1** | Resistor Film | **10 kΩ**, 1/4 Watt, toleransi 1% / 5% | Axial Through-Hole | 1 pcs | **PERLU DIBELI** | Pull-up jalur data DHT22 (GPIO21) |
| **R2** | Resistor Film | **220 Ω**, 1/4 Watt | Axial Through-Hole | 1 pcs | **PERLU DIBELI** | Pembatas arus kanal Merah LED RGB (GPIO4) |
| **R3** | Resistor Film | **220 Ω**, 1/4 Watt | Axial Through-Hole | 1 pcs | **PERLU DIBELI** | Pembatas arus kanal Hijau LED RGB (GPIO3) |
| **R4** | Resistor Film | **220 Ω**, 1/4 Watt | Axial Through-Hole | 1 pcs | **PERLU DIBELI** | Pembatas arus kanal Biru LED RGB (GPIO2) |
| **R5** | Resistor Film | **1 kΩ**, 1/4 Watt | Axial Through-Hole | 1 pcs | **PERLU DIBELI** | Resistor Basis transistor Q1 dari GPIO5 |
| **C1** | Kapasitor Elco | **100 µF / 16V atau 25V** | Radial Elektrolit (Dia 5mm, Pitch 2.0-2.5mm) | 1 pcs | **PERLU DIBELI** | Bulk buffer & peredam ripple daya +5V saat kipas start |
| **C2** | Kapasitor Keramik | **100 nF (0.1 µF)**, kode bodi `104` | Radial Keramik (Pitch 2.5 mm) | 1 pcs | **PERLU DIBELI** | Decoupling noise frekuensi tinggi pada rail +5V |

*Rekomendasi pembelian:* Resistor dapat dibeli dalam kemasan per renteng (10 pcs / strip) karena harganya sangat terjangkau.

---

## 5. Konektor, Terminal, & Socket PCB

| Ref Des | Komponen | Spesifikasi Fisik | Jumlah | Status | Keterangan |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **U1** | **Screw Terminal Block** | **KF301-2P** (Pitch 5.00 mm, 2-pin) | 1 pcs | **PERLU DIBELI** | Input daya utama (+5V dan GND) dari panel jack |
| **CN1** | **Konektor JST-XH 2-Pin Siku** | JST-XH 2.54 mm Horizontal / Right-Angle Male Header | 1 pcs | **PERLU DIBELI** | Output daya terkontrol untuk Fan 5V (beli beserta housing female + pin crimp jika perlu) |
| **H1** | Female Pin Header | 1x4 Pin, Pitch 2.54 mm, Straight | 1 pcs | **PERLU DIBELI** | Konektor jumper sensor MQ-7 |
| **H2** | Female Pin Header | 1x4 Pin, Pitch 2.54 mm, Straight | 1 pcs | **PERLU DIBELI** | Konektor jumper modul OLED I2C |
| **H3** | Female Pin Header | 1x4 Pin, Pitch 2.54 mm, Straight | 1 pcs | **PERLU DIBELI** | Konektor jumper sensor MQ-2 |
| **H4** | Female Pin Header | 1x3 Pin, Pitch 2.54 mm, Straight | 1 pcs | **PERLU DIBELI** | Konektor jumper sensor DHT22 |
| **MCU Socket** | Female Pin Header | 1x8 Pin, Pitch 2.54 mm, Straight (2 baris) | 2 pcs | **PERLU DIBELI** | Dudukan modul ESP32-C3 SuperMini agar dapat dilepas-pasang (dapat dipotong dari strip female 1x40) |

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
4. **Orientasi Kapasitor Elco C1:**
   * Garis putih/negatif pada bodi kapasitor wajib menghadap ke Pad bertanda minus / GND (sisi kiri dekat U1).
