# 📦 Berkas DXF Desain 3D Enclosure Terintegrasi V2 (POLTEKOM ESS)

Folder ini khusus memuat berkas DXF **Revisi Final V2** untuk pemodelan 3D di **Onshape**.
Terpisah 100% dari folder desain lama (`onshape_dxf/`).

## 📁 Daftar Berkas DXF Siap Import ke Onshape

| No | Berkas Berurutan | Berkas Standar | Dimensi (mm) | Tebal Extrude | Keterangan & Komponen |
|:--:|:---|:---|:---:|:---:|:---|
| 1 | `1_pelat_penutup_atas.dxf` | `pelat_penutup_atas.dxf` | 134.0 x 104.0 | 3.0 mm | **Pelat Atas Polos:** Overhang 7.0 mm (lebih ringkas & proporsional), 4 lubang spacer M3 sudut mepet dinding (margin 3.5 mm), 10 slot tertutup (0 komponen) |
| 2 | `2_pelat_dasar_bawah.dxf` | `pelat_dasar_bawah.dxf` | 134.0 x 104.0 | 3.0 mm | **Pelat Bawah Polos:** Overhang 7.0 mm (lebih ringkas & proporsional), 4 lubang spacer M3 sudut mepet dinding (margin 3.5 mm), 10 slot tertutup (0 komponen) |
| 3 | `3_dinding_depan.dxf` | `dinding_depan.dxf` | 120.0 x 50.0 | 3.0 mm | **Dinding Depan:** Jendela OLED 0.96" (25.0x17.0 mm), pitch 21x22 mm, LED RGB (Dia 5.5 mm), 4 ventilasi, DHT22 (16.0x21.0 mm) |
| 4 | `4_sekat_tengah.dxf` | `sekat_tengah.dxf` | 120.0 x 50.0 | 3.0 mm | **Sekat Tengah:** Purus atas, bawah, kotak purus samping kiri & kanan (18x3 mm). Dudukan MQ-7, MQ-2, 4 baut PCB, slot kabel fan (0.8 x 0.6 cm) |
| 5 | `5_dinding_belakang.dxf` | `dinding_belakang.dxf` | 120.0 x 50.0 | 3.0 mm | **Dinding Belakang Polos:** Solid panel penutup belakang tunnel + slot mortise sudut |
| 6 | `6_dinding_sisi_kiri.dxf` | `dinding_sisi_kiri.dxf` | 84.0 x 50.0 | 3.0 mm | **Dinding Sisi Kiri:** 3 Kisi ventilasi pendingin ESP32, Slot Purus Sekat Tengah (3.10x18 mm), Filter Hexagonal 37 lubang reguler |
| 7 | `7_dinding_sisi_kanan.dxf` | `dinding_sisi_kanan.dxf` | 84.0 x 50.0 | 3.0 mm | **Dinding Sisi Kanan:** Port Power DC Jack Dia 11.60 mm (DC-022 pasaran), Slot Purus Sekat Tengah (3.10x18 mm), Dudukan Kipas Exhaust 3010 |
| 8 | `8_spacer_nylon_male_female_m3_50mm.dxf` | `spacer_nylon_male_female_m3_50mm.stl` | Hex 5.4 x 6.0 mm, Bodi 50mm, Male Stud 6mm, Female 8mm | **50.0 mm Bodi + 6.0 mm Stud** | **Spacer Nylon Male-to-Female M3 x 50mm:** Sesuai datasheet OnlyScrews. Menghubungkan Pelat Atas (baut M3x10 masuk 7mm ke lubang female) dan Pelat Bawah (stud male 6mm menembus pelat 3mm dan dikunci mur M3). 100% Watertight Solid STL! |
| 9 | `9_baut_pan_head_m3_10mm.dxf` | `baut_pan_head_m3_10mm.dxf` / `.stl` | Kepala Dia 5.0 mm, Tinggi 2.5 mm, Batang M3 x 10 mm | **12.5 mm** Total (Batang 10mm + Kepala 2.5mm) | **Baut Phillips Pan Head M3 x 10mm:** Baut tunggal mandiri. Tersedia format **DXF (revolve)** dan **3D STL siap pakai**! |
| 10 | `10_baut_dan_mur_m3_10mm.stl` | `baut_dan_mur_m3_10mm.stl` / `.dxf` | Kepala Ø 5.0mm, Batang 10mm, Mur Hex 5.5mm | **1 Unit Terpadu (Solid STL)** | **Baut M3 x 10mm + Mur Hex M3 Terintegrasi:** 1 Solid Part jadi satu (tidak terpisah). Celah jepit akrilik presisi **3.0 mm**, langsung pas dimasukkan ke lubang akrilik! |
| 11 | `11_mur_hex_m3.stl` | `mur_hex_m3.stl` | Kunci Pas 5.5 mm, Tebal 2.4 mm, Lubang M3 | **2.4 mm** (Standar DIN 934) | **Mur Heksagonal M3 Standalone:** Mur M3 terpisah jika dibutuhkan untuk perakitan mandiri di Onshape. |
| 12 | `12_modul_sensor_mq2.dxf` | `12_modul_sensor_mq2.stl` | 20.0 x 32.0 mm, Canister Ø 20.5 mm, Pitch 15x27 mm | **Board 1.6 mm, Canister 10.0 mm** | **Modul Sensor MQ-2 (LPG/Gas):** Breakout board dengan 4 lubang baut M3, silinder canister Ø 20.5 mm, dan header 4-pin. Siap untuk simulasi assembly 3D! |
| 13 | `13_modul_sensor_mq7.dxf` | `13_modul_sensor_mq7.stl` | 20.0 x 32.0 mm, Canister Ø 18.4 mm, Pitch 15x27 mm | **Board 1.6 mm, Canister 10.0 mm** | **Modul Sensor MQ-7 (CO):** Breakout board dengan 4 lubang baut M3, silinder canister Ø 18.4 mm, dan header 4-pin. Siap untuk simulasi assembly 3D! |
| 14 | `14_pcb_ess_5.dxf` | `14_pcb_ess_5.stl` | 70.0 x 40.0 mm, Pitch Baut 64.4 x 34.4 mm | **Board 1.6 mm, Komponen 3.5 - 10 mm** | **PCB Utama ESS 5:** Board mikrokontroler dengan 4 lubang mounting M3, modul ESP32-C3 SuperMini, soket sensor MQ, OLED, dan terminal KF301. Siap disimulasikan di Onshape! |

---

## 🚀 Panduan Cepat Pemodelan 3D di Onshape:
1. **Untuk 7 Dinding & Pelat Akrilik (Part 1 s.d. 7):**
   - Buat Sketch baru, klik **Insert DXF/DWG**, pilih file DXF.
   - Klik **Extrude** dengan Depth = **3.0 mm** (Pilih mode **New** untuk setiap part agar menjadi part terpisah).
2. **Untuk Spacer Nylon M3 x 50mm (Part 8):**
   - **Direct 3D STL (Paling Praktis):** Klik tombol **+ (Insert / Import)** di kiri bawah Onshape $\rightarrow$ pilih file `spacer_nylon_hex_m3_50mm.stl`.
   - **DXF Sketch:** Buat Sketch baru, insert `8_spacer_nylon_hex_m3_50mm.dxf`, lalu **Extrude** setinggi **50.0 mm**.
3. **Untuk Baut M3 x 10mm + Mur M3 Terintegrasi 1 Part (Part 10 - Rekomendasi Utama):**
   - **Direct 3D STL:** Klik tombol **+ (Insert / Import)** di kiri bawah Onshape $\rightarrow$ pilih file `10_baut_dan_mur_m3_10mm.stl` (atau `baut_dan_mur_m3_10mm.stl`).
   - Model langsung muncul sebagai **1 kesatuan solid** dengan kepala baut dan mur heksagonal yang sudah mengunci pada jarak jepit **3.0 mm** (sesuai tebal pelat akrilik).
   - Tidak perlu pusing menggabungkan baut dan mur secara manual di Assembly!
4. **Di Tab Assembly:**
   - Gunakan **Fastened Mate** antara purus tenon dan slot mortise dinding.
   - Pasang 4 pilar spacer di 4 lubang sudut luar antara Pelat Atas dan Pelat Bawah.
   - Pasang baut/mur untuk penguncian modul internal (PCB, Fan, OLED) dan spacer luar. Semua komponen terkunci kokoh!
