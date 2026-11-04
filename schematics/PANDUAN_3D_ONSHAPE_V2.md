# 📐 Panduan Pemodelan 3D Onshape & Laser Cutting V2: Enclosure Terintegrasi Horizontal

Dokumen ini memuat panduan teknis **Revisi Final V2** yang telah diselaraskan **100% presisi** dengan arahan pengguna:
* **Pelat Atas & Pelat Bawah ($134.0 \times 104.0\text{ mm}$):**
  * Diberi **bibir / overhang $7.0\text{ mm}$ di seluruh 4 sisi luar persis seperti foto referensi boks akrilik biru (Foto 1 & Foto 3)**, lebih ringkas, proporsional, dan menempel rapi ke dinding.
  * **4 Lubang Baut Spacer M3 ($\varnothing 3.20\text{ mm}$)** ditempatkan di 4 sudut luar pada $(3.5, 3.5), (130.5, 3.5), (3.5, 100.5), (130.5, 100.5)$ dengan sudut luar membulat (*fillet*) $R=3.5\text{ mm}$ konsentris dengan lubang baut spacer.
  * **Rapat & Presisi Mengikuti Datasheet Baut (Foto 4):**
    * Baut: Phillips Pan Head M3 x 10mm, diameter kepala baut = **$5.0\text{ mm}$** (radius $2.5\text{ mm}$).
    * Jarak dari pusat lubang ke dinding: **$3.5\text{ mm}$**.
    * Celah bersih kepala baut ke dinding samping: **$1.0\text{ mm}$**.
    * Celah bersih pilar spacer heksagonal M3 ($5.0\text{ mm} - 5.5\text{ mm}$) ke dinding: **$0.33\text{ mm} - 0.61\text{ mm}$** (menempel rapi tanpa menyenggol atau menjepit dinding!).
    * Sisa daging akrilik melingkar di luar kepala baut: **$1.0\text{ mm}$** (sangat rapi melingkari kepala baut persis Foto 3).
  * **Semua 10 Slot Purus Tertutup Rapat (*Closed Slots*):** Daging akrilik luar selebar $7.0\text{ mm}$ mengunci dinding samping kiri, kanan, depan, belakang, dan sekat tengah secara absolut dari arah luar.
  * Polos bersih tanpa lubang komponen sama sekali (*clean plates*, 0 komponen).
* **Dinding Depan ($120.0 \times 50.0\text{ mm}$):** Diselaraskan **tegak lurus 1:1 dengan PCB pada Sekat Tengah**:
  * Jendela Layar OLED 0.96" (**$25.00 \times 17.00\text{ mm}$**, $rx=1.5\text{ mm}$) di Center $(38.50, 25.00)$ + 4 lubang baut M2 $\varnothing 2.5\text{ mm}$ dengan **pitch aktual $21.00\text{ mm}$ (horizontal) $\times 28.20\text{ mm}$ (vertikal)** pada $(28.00, 14.00), (49.00, 14.00), (28.00, 36.00), (49.00, 36.00)$.
  * Lubang tembus indikator LED RGB 5mm ($\varnothing 5.5\text{ mm}$) di Center $(65.64, 35.61)$ $\rightarrow$ **TEPAT TEGAK LURUS DI ATAS PORT LED D1 PADA PCB** ($X_{box} = 25.0 + 40.64 = 65.64\text{ mm}$).
  * 4 baris celah kisi-kisi ventilasi pasif ($12.0 \times 2.0\text{ mm}$, $rx=1.0\text{ mm}$) di Center $X = 62.00\text{ mm}$ persis di bawah LED RGB ($Z = 27.0, 23.0, 19.0, 15.0\text{ mm}$).
  * Jendela sensor DHT22 bodi kotak putih timbul ber-kisi **$16.00 \times 21.00\text{ mm}$** ($rx=1.0\text{ mm}$, hanya kotak sensor yang menonjol keluar) di Center $(86.75, 30.00)$, terbentang di $Z \in [19.50, 40.50\text{ mm}]$.
  * 2 lubang baut mounting DHT22 (**pitch vertikal tepat $28.0\text{ mm}$ / $2.8\text{ cm}$**):
    * **Lubang Atas (kuping bodi putih):** $\varnothing 2.60\text{ mm}$ (baut M2.5 / M2 lebih kecil) pada $(86.75, 42.50)$.
    * **Lubang Bawah (PCB sensor hitam):** $\varnothing 3.20\text{ mm}$ (baut M3 - dinaikkan) pada $(86.75, 14.50)$.
  * Purus standar V2: 2 purus atas, 2 purus bawah pada $X \in [20, 40]$ dan $[80, 100]$ + slot mortise samping kiri & kanan ($3.10 \times 18.0\text{ mm}$).
* **Dinding Sekat Tengah ($120.0 \times 50.0\text{ mm}$):**
  * Bodi dalam: $114.0 \times 50.0\text{ mm}$ (duduk pas di antara permukaan dalam Dinding Kiri $X=3.0$ dan Dinding Kanan $X=117.0$).
  * **2 Purus Atas & 2 Purus Bawah** ($20.0 \times 3.0\text{ mm}$ pada $X \in [20, 40]$ dan $[80, 100]$) yang mengunci ke pelat atas dan pelat bawah.
  * **KOTAK PURUS SAMPING KIRI & KANAN (Tinggi 18.0 mm, tebal 3.0 mm, $Z \in [16.0, 34.0\text{ mm}]$):**
    * Purus Samping Kiri: Menjorok $3.0\text{ mm}$ ke kiri ($X \in [0.0, 3.0\text{ mm}]$) mengunci ke slot Dinding Kiri.
    * Purus Samping Kanan: Menjorok $3.0\text{ mm}$ ke kanan ($X \in [117.0, 120.0\text{ mm}]$) mengunci ke slot Dinding Kanan.
  * Layout komponen dan PCB:
    * 4 lubang baut dudukan PCB ESS 5 $\varnothing 3.2\text{ mm}$ (pitch $64.4 \times 34.4\text{ mm}$).
    * Dudukan sensor MQ-7 (CO): $\varnothing 18.4\text{ mm}$ di tengah $(47.0, 14.5)$ + 4 lubang baut M3 (pitch $15.0 \times 27.0\text{ mm}$, lubang bawah di $Y = 4.5\text{ mm}$ dengan toleransi baut kepala $\varnothing 5\text{ mm}$ sebesar $2.0\text{ mm}$ dari pelat bawah).
    * Dudukan sensor MQ-2 (LPG): $\varnothing 20.5\text{ mm}$ di tengah $(73.0, 15.5)$ + 4 lubang baut M3 (pitch $15.0 \times 27.0\text{ mm}$, lubang bawah di $Y = 4.5\text{ mm}$ dengan toleransi baut kepala $\varnothing 5\text{ mm}$ sebesar $2.0\text{ mm}$ dari pelat bawah).
    * Kedua modul sensor kini **simetris tepat di tengah PCB** (titik tengah kedua sensor di $X = 60.0\text{ mm}$, jarak ke tepi lubang PCB kiri & kanan sama persis $11.7\text{ mm}$).
    * Slot KABEL FAN (**$0.8\text{ cm} \times 0.6\text{ cm}$ / $8.0 \times 6.0\text{ mm}$**, $R=1.2\text{ mm}$) di area kanan bawah $(98.0, 16.0)$.
* **Dinding Belakang ($120.0 \times 50.0\text{ mm}$):** Dibuat **polos solid** + slot mortise sudut samping kiri & kanan ($3.10 \times 18.0\text{ mm}$).
* **Dinding Samping Kiri & Kanan ($84.0 \times 50.0\text{ mm}$ - Selaras 100% Pinout PCB):**
  * **Sisi Kanan:** Port DC-022 Barrel Jack $\varnothing 11.60\text{ mm}$ di depan (**tepat di samping Terminal 5V KF301 pada sisi kanan PCB & berdekatan dengan kipas exhaust**) + 2 celah pendingin + **Slot Purus Sekat Tengah ($3.10 \times 18.0\text{ mm}$ di $X=42.0\text{ mm}$, $Z \in [16, 34]$)** + Dudukan Exhaust Fan 3010 $\varnothing 28.2\text{ mm}$ (4 lubang baut M3 pitch $24.0 \times 24.0\text{ mm}$) di belakang + purus samping depan & belakang ($18.0 \times 3.0\text{ mm}$).
  * **Sisi Kiri:** 3 Celah kisi-kisi ventilasi di depan (**tepat di samping modul ESP32-C3 SuperMini pada sisi kiri PCB**) + **Slot Purus Sekat Tengah ($3.10 \times 18.0\text{ mm}$ di $X=42.0\text{ mm}$, $Z \in [16, 34]$)** + **Filter Hexagonal 37 lubang $\varnothing 2.3\text{ mm}$ (inlet udara tunnel reguler penuh)** di belakang + purus samping depan & belakang ($18.0 \times 3.0\text{ mm}$).
* **Dimensi Luar Pelat:** Panjang $134.0\text{ mm}$ $\times$ Lebar $104.0\text{ mm}$ $\times$ Tebal $3.0\text{ mm}$ (dengan bibir overhang $7.0\text{ mm}$ kompak & rapi).
* **Dimensi Bodi Dinding:** Panjang $120.0\text{ mm}$ $\times$ Lebar $90.0\text{ mm}$ $\times$ Tinggi $50.0\text{ mm}$.
* **Dimensi Dalam Bersih:** Tinggi dalam bersih **$50.0\text{ mm}$ ($5\text{ cm}$)**.
* **Bahan:** Akrilik Bening / Warna Tebal $3.0\text{ mm}$ (toleransi slot $3.10\text{ mm}$).

---

## 1. Pembagian Ruang Dalam (*Dual-Chamber Architecture*)

```
  +--------------------------------- DINDING BELAKANG (120 x 50 mm) - POLOS SOLID ------------------+
  |  [Inlet Honeycomb]                                                           [Exhaust Kipas]    |
  |  31 lubang Ø 2.3 mm        RUANG 2 (BELAKANG): TUNNEL AIRFLOW SENSOR GAS     Bore Ø 28.2 mm     |
  |  di dinding kiri                 (Dimensi Bersih: 114 x 40.5 x 50 mm)        di dinding kanan   |
  |  [Slot Sekat Tengah]                                                         [Slot Sekat Tengah]|
  +================================== SEKAT TENGAH (120 x 50 mm) - PLEK SCREENSHOT =================+
  |  [Purus Kiri 18x3]         (O) MQ-7 (CO)                  (O) MQ-2 (Gas)     [Purus Kanan 18x3] |
  |                            Ø 18.4 mm + 4 M3               Ø 20.5 mm + 4 M3   [KABEL FAN]        |
  |                            + 4 Lubang Dudukan PCB ESS 5 (Pitch 64.4 x 34.4)  8 x 4.5 mm         |
  |                                                                                                 |
  |  [Ventilasi Sisi Kiri]                                                       [DC Barrel Jack]   |
  |  3 celah pendingin         RUANG 1 (DEPAN): CASE PCB ELEKTRONIKA             DC-022 Ø 12.0 mm   |
  |  di samping ESP32                (Dimensi Bersih: 114 x 40.5 x 50 mm)        di samping KF301   |
  |                                                                                                 |
  |      [== OLED 0.96" ==]         |||| Ventilasi      (O) LED RGB         [== DHT22 ==]           |
  |      Jendela 24.5x16.5 mm       4 baris celah       Ø 5.5 mm            Jendela 16.1x26.0 mm    |
  +---------------------------------- DINDING DEPAN (120 x 50 mm) - FOTO BIRU MUDA ----------------+
  <--------------------------------------- Total 120.0 mm ------------------------------------------>
```

---

## 2. Berkas DXF V2 Siap Pakai di Onshape (Folder Khusus: `dxf_desain_3d_enclosure_v2/`)

> [!TIP]
> Berkas DXF untuk pemodelan 3D disimpan di folder baru **`dxf_desain_3d_enclosure_v2/`** (terpisah 100% dari folder lama `onshape_dxf/`).
> Anda dapat memilih berkas dengan penomoran urut (`1_...` s/d `7_...`) atau nama standar sesuai kenyamanan impor Onshape.

| No | Berkas Berurutan | Berkas Standar | Dimensi | Keterangan & Komponen |
| :---: | :--- | :--- | :---: | :--- |
| 1 | `1_pelat_penutup_atas.dxf` | `pelat_penutup_atas.dxf` | $140 \times 110\text{ mm}$ | **Pelat Penutup Atas:** Polos bersih (10 slot purus tertutup + 4 lubang spacer M3 sudut di luar bodi dinding, overhang 10.0 mm persis akrilik biru, 0 komponen) |
| 2 | `2_pelat_dasar_bawah.dxf` | `pelat_dasar_bawah.dxf` | $140 \times 110\text{ mm}$ | **Pelat Dasar Bawah:** Polos bersih (10 slot purus tertutup + 4 lubang spacer M3 sudut di luar bodi dinding, overhang 10.0 mm persis akrilik biru, 0 komponen) |
| 3 | `3_dinding_depan.dxf` | `dinding_depan.dxf` | $120 \times 50\text{ mm}$ | **Dinding Depan:** Jendela OLED 0.96", 4 ventilasi, LED RGB 5mm, jendela DHT22, serta **Slot Blok Purus Samping Kiri & Kanan ($18.0 \times 3.1\text{ mm}$)** untuk mengunci Dinding Sisi Kiri & Kanan |
| 4 | `4_sekat_tengah.dxf` | `sekat_tengah.dxf` | $120 \times 50\text{ mm}$ | **Sekat Tengah:** 2 purus atas, 2 purus bawah, serta **kotak purus samping kanan & kiri** ($18.0 \times 3.0\text{ mm}$). Dudukan MQ-7 $\varnothing18.4$, MQ-2 $\varnothing20.5$, 4 baut PCB, slot KABEL FAN |
| 5 | `5_dinding_belakang.dxf` | `dinding_belakang.dxf` | $120 \times 50\text{ mm}$ | **Dinding Belakang:** Solid panel penutup belakang tunnel + **Slot Blok Purus Samping Kiri & Kanan ($18.0 \times 3.1\text{ mm}$)** untuk mengunci Dinding Sisi Kiri & Kanan |
| 6 | `6_dinding_sisi_kiri.dxf` | `dinding_sisi_kiri.dxf` | $84 \times 50\text{ mm}$ | **Dinding Samping Kiri:** **Blok Purus Depan & Belakang ($18.0 \times 3.0\text{ mm}$)** + 3 Kisi ventilasi ESP32 + **Slot Purus Sekat Tengah ($3.10 \times 18.0\text{ mm}$)** + Filter Hexagon Penuh 37 lubang $\varnothing2.3\text{ mm}$ (Inlet udara tunnel) |
| 7 | `7_dinding_sisi_kanan.dxf` | `dinding_sisi_kanan.dxf` | $84 \times 50\text{ mm}$ | **Dinding Samping Kanan:** **Blok Purus Depan & Belakang ($18.0 \times 3.0\text{ mm}$)** + DC Barrel Jack $\varnothing11.6\text{ mm}$ (standar pasaran DC-022) + **Slot Purus Sekat Tengah ($3.10 \times 18.0\text{ mm}$)** + Dudukan Exhaust Fan 3010 $\varnothing28.2\text{ mm}$ |

---

## 3. Berkas Laser Cutting V2 Siap Cetak

* 👉 [`laser_cutting_v2_integrated_box.svg`](file:///d:/MAGANG/IoT/Bismillah/laser_cutting_v2_integrated_box.svg)
* Lembaran: $400 \times 290\text{ mm}$ (tebal akrilik $3.0\text{ mm}$).
* Garis potong merah (`#ff0000`, hairline $0.2\text{ mm}$).
