# 🚀 Panduan Realisasi Desain 3D di Onshape
**Smart Environmental Sensing System (ESS)**  
*Laboratorium Mekatronika, Politeknik Kota Malang (POLTEKOM)*

Panduan ini disusun khusus untuk membantu Anda merealisasikan model 3D dari **Desain 1 (Tunnel Sensor Gas)** dan **Desain 2 (Case PCB Alat)** ke dalam software **Onshape (Cloud CAD)** secara presisi, cepat, dan profesional.

---

## 📁 Berkas DXF Siap Pakai untuk Onshape
Seluruh kontur 2D telah diekspor ke format **DXF (Unit: Milimeter)** dengan poligon tertutup (*closed loops*) sehingga siap di-*extrude* langsung menjadi solid 3D di Onshape:

* **Lokasi Folder Lokal:**  
  📂 [`d:\MAGANG\IoT\Bismillah\onshape_dxf\`](file:///d:/MAGANG/IoT/Bismillah/onshape_dxf/)  
  📂 [`EnvironmentalSensing-main/schematics/dxf/`](file:///d:/MAGANG/IoT/Bismillah/EnvironmentalSensing-main/schematics/dxf/)

### Daftar File DXF:
#### 1. Desain 1: Tunnel Sensor Gas ($120 \times 50 \times 44\text{ mm}$)
1. `tunnel_pelat_atas.dxf` *(Pelat Atas - Dudukan MQ-2 $\varnothing 20.5\text{ mm}$ & MQ-7 $\varnothing 18.4\text{ mm}$)*
2. `tunnel_pelat_bawah.dxf` *(Pelat Bawah - Lantai & Lubang Bracket Base)*
3. `tunnel_dinding_samping.dxf` *(Dinding Samping $93 \times 44\text{ mm}$ - Pas antara Inlet & Outlet)*
4. `tunnel_inlet_depan.dxf` *(Inlet Depan - Kisi-kisi Honeycomb 31 Lubang $\varnothing 2.3\text{ mm}$, Pitch $3.7\text{ mm}$)*
5. `tunnel_outlet_fan.dxf` *(Outlet Belakang - Dudukan Kipas 30x30 mm & Lubang Angin $\varnothing 22\text{ mm}$)*

#### 2. Desain 2: Case PCB Alat ($96 	imes 50 	imes 46	ext{ mm}$)
*(Catatan: Ukuran pelat atas case tepat $96 	imes 50	ext{ mm}$ rata/flush dengan dinding samping luar tanpa bibir/overhang yang menonjol, 4 sudut melingkar/fillet $R = 3.5	ext{ mm}$ sama persis dengan tunnel, serta 4 lubang spacer internal M3 di dalam boks!)*
1. `case_pelat_atas.dxf` *(Pelat Atas $96 	imes 50	ext{ mm}$ - Rata Dinding Samping, Sudut Melingkar $R=3.5	ext{ mm}$, Jendela DHT22 $15.5 	imes 25.5	ext{ mm}$ + 2 Baut Pitch $35	ext{ mm}$, Layar OLED, LED RGB, 4 Lubang Spacer Internal M3)*
2. `case_dinding_kiri_usbc.dxf` *(Dinding Kiri - Bersih tanpa lubang USB-C, dilengkapi 3 baris kisi ventilasi pendingin)*
3. `case_dinding_kanan_power.dxf` *(Dinding Kanan - Lubang Panel Mount DC Barrel Jack DC-022 $\varnothing 12\text{ mm}$ + 2 kisi ventilasi)*
4. `case_dinding_depan.dxf` *(Dinding Depan - 3 baris kisi ventilasi bertingkat muka boks)*
5. `case_dinding_belakang.dxf` *(Dinding Belakang - 3 baris kisi ventilasi identik dinding depan, tertutup rapi)*

---

## 🛠️ Langkah Demi Langkah Pemodelan di Onshape

### METODE TERCEPAT: Import DXF -> Extrude 3 mm (100% Presisi)

#### Langkah 1: Buat Dokumen Baru di Onshape
1. Buka browser dan login ke [cad.onshape.com](https://cad.onshape.com).
2. Klik **Create** -> **Document**.
3. Beri nama dokumen: `ESS_Enclosure_3D_Tunnel_and_Case`.

#### Langkah 2: Upload File DXF ke Dokumen Onshape
1. Di pojok kiri bawah tampilan Onshape, klik tombol **`+` (Insert new element)**.
2. Pilih **Import...**.
3. Masuk ke folder `d:\MAGANG\IoT\Bismillah\onshape_dxf\` dan pilih semua file `.dxf`.
4. File DXF akan muncul sebagai tab-tab terpisah di bagian bawah dokumen Anda.

#### Langkah 3: Ekstrusi Part 3D di Part Studio
1. Buka tab **Part Studio 1**.
2. Buat sketch baru pada **Top Plane**:
   * Klik tombol **Sketch** -> klik bidang **Top Plane**.
   * Klik icon **Insert DXF or DWG** di toolbar (atau tekan `Search Tools` ketik "DXF").
   * Pilih file `tunnel_pelat_atas.dxf`.
   * Sketsa kontur pelat beserta seluruh lubang baut & lingkaran filter akan otomatis masuk tepat pada skala 1:1 ($120 \times 50\text{ mm}$).
   * Klik centang hijau (✓).
3. Buat solid akrilik:
   * Klik tombol **Extrude**.
   * Klik area permukaan sketsa tadi.
   * Pilih opsi: **Solid** -> **New**.
   * Masukkan Depth: **`3 mm`**.
   * Klik centang hijau (✓).
   * Pada daftar *Parts* di kiri bawah, ganti nama `Part 1` menjadi `Tunnel Pelat Atas`.
4. **Ulangi untuk part lainnya**:
   * Anda bisa membuat Part Studio baru untuk masing-masing pelat, atau membuat semuanya di Part Studio yang sama dengan sketch terpisah.

---

### Langkah 4: Perakitan 3D di Assembly (Tab Assembly 1)
1. Buka tab **Assembly 1**.
2. Klik **Insert** -> Masukkan semua part akrilik yang telah di-*extrude*:
   * `Pelat Bawah` (Klik kanan -> **Fix** agar menjadi patokan diam di origin).
   * `Dinding Samping Kiri & Kanan`
   * `Inlet Depan`
   * `Outlet Kipas Belakang`
   * `Pelat Atas`
3. Pasang menggunakan **Fastened Mate (M)**:
   * **Mengunci Tab ke Slot:** Klik pusat bidang bawah tab pada dinding samping, lalu klik pusat bidang bawah slot pada pelat bawah. Tab akan otomatis mengunci pas (*snap*) ke celah akrilik!
   * **Memasang Pelat Atas:** Gunakan Fastened Mate antara slot pelat atas dengan tab atas dinding samping.
4. Kotak tunnel langsung terangkai rapat dan presisi tanpa celah tabrakan!

---

## 🎨 Menambahkan Material & Visual Realistis (Render Look)
Agar bapak dosen / pembimbing terkesan (*impressed*):
1. **Warna Akrilik Transparan / Smoke Black:**
   * Di daftar Parts (atau Assembly), klik kanan part akrilik -> **Edit Appearance**.
   * Pilih warna putih/abu-abu terang atau biru muda transparan.
   * Geser slider **Opacity** ke kisaran **0.40 - 0.50 (40-50%)**.
   * Pelat akrilik akan tampak bening transparan seperti kaca/akrilik sungguhan!
2. **Menambahkan Hardware Standar (M3 Spacers & Screws):**
   * Di Onshape Assembly, klik **Insert** -> **Standard Content**.
   * Pilih:
     * Category: **Fasteners** -> **Standoffs** / **Spacers** (Pilih Hex Standoff M3 x 40 mm).
     * Screws: **Pan Head / Button Head M3 x 6 mm**.
   * Pasang 4 standoff di 4 lubang sudut luar!

---

## 💡 Alternatif: Import Model Komponen Elektronik Siap Pakai
Jika ingin memasukkan model 3D kipas, OLED, DHT22, atau sensor MQ:
* Anda bisa mengunduh model 3D STEP (`.step` / `.stp`) gratis dari **GrabCAD** atau **3D ContentCentral**:
  1. Kipas 3010 (Fan 30x30x10 mm)
  2. Modul MQ-2 / MQ-7
  3. Modul OLED 0.96 inch I2C
  4. Modul DHT22 AM2302
* Klik **`+` -> Import** file `.step` tersebut ke Onshape, lalu masukkan ke Assembly menggunakan Mate Connectors!

---

*Apakah kamu ingin kita mulai langkah pertama sekarang di Onshape? Aku bisa pandu step-by-step tiap klik dan fiturnya!*
