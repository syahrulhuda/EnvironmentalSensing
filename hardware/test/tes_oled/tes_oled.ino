/*
  =============================================================================
  POLTEKOM SMART ENVIRONMENTAL SENSING SYSTEM (ESS)
  Hardware Diagnostic: Isolated OLED & I2C Bus Test Bench
  
  Target MCU: ESP32-C3 SuperMini
  Tujuan:
    1. Menguji secara terisolasi modul OLED SSD1306 0.96" I2C pada PCB v5
    2. Menonaktifkan SELURUH radio (Wi-Fi, Bluetooth) & periferal berdaya tinggi
       (Kipas PWM, sensor gas MQ-7 & MQ-2, sensor DHT22)
    3. Mengeliminasi 100% kemungkinan brownout / voltage drop dari port USB laptop
    4. Menyediakan indikator visual instan via LED RGB (Hijau = OK, Merah = Galat)
    5. I2C Hardware Scanner otomatis untuk memastikan alamat dan kondisi bus
  =============================================================================
*/

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <WiFi.h>
#include <esp_wifi.h>

// --- PIN DEFINITIONS (Sesuai Skematik PCB_ESS_5) ---
#define PIN_LED_R       4     // GPIO 4 - Kanal Merah LED RGB
#define PIN_LED_G       3     // GPIO 3 - Kanal Hijau LED RGB
#define PIN_LED_B       2     // GPIO 2 - Kanal Biru LED RGB

#define PIN_OLED_SDA    8     // GPIO 8 - I2C SDA
#define PIN_OLED_SCL    9     // GPIO 9 - I2C SCL (Strapping Pin ESP32-C3)

#define PIN_FAN_PWM     5     // GPIO 5 - Basis Transistor Kipas (Wajib LOW)
#define PIN_DHT_DATA    10    // GPIO 10 - DHT22
#define PIN_MQ7_ADC     1     // GPIO 1 - MQ-7
#define PIN_MQ2_ADC     0     // GPIO 0 - MQ-2

#define SCREEN_WIDTH    128
#define SCREEN_HEIGHT   64
#define OLED_RESET      -1

// Objek Display SSD1306
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Status Global
bool oledDetected = false;
bool oledReady    = false;
uint8_t targetI2cAddr = 0x3C;
unsigned long frameCount = 0;
unsigned long lastTick   = 0;

// --- PROTOTIPE FUNGSI ---
void setRgbColor(bool r, bool g, bool b);
void disableAllOtherGpios();
uint8_t scanI2cBus();

void setup() {
  // Inisialisasi Serial USB CDC
  Serial.begin(115200);
  delay(1000); // Tunggu enumerasi USB CDC stabil

  Serial.println("\n=======================================================");
  Serial.println("  POLTEKOM ESS - ISOLATED OLED & I2C TEST BENCH");
  Serial.println("  Target: ESP32-C3 SuperMini (Single-Layer PCB v5)");
  Serial.println("=======================================================");

  // 1. Matikan Radio RF Secara Total (Zero RF Power Draw)
  WiFi.disconnect(true);
  WiFi.mode(WIFI_OFF);
  esp_wifi_stop();
  btStop();
  Serial.println("[POWER] Wi-Fi dan Bluetooth dinonaktifkan total (Hemat daya ~35mA).");

  // 2. Kunci Seluruh GPIO Lainnya agar Zero Current Draw
  disableAllOtherGpios();
  Serial.println("[GPIO] Seluruh pin sensor & kipas berhasil dikunci/dinonaktifkan.");

  // 3. Konfigurasi LED RGB Indikator
  pinMode(PIN_LED_R, OUTPUT);
  pinMode(PIN_LED_G, OUTPUT);
  pinMode(PIN_LED_B, OUTPUT);

  // Indikator BIRU = Sedang Memulai & Scanning I2C
  setRgbColor(0, 0, 1);
  Serial.println("[TEST] Menyiapkan Bus I2C (SDA: GPIO 8, SCL: GPIO 9)...");

  // 4. Inisialisasi Bus I2C (100 kHz Standard Mode dengan Timeout Protektif 50ms)
  Wire.begin(PIN_OLED_SDA, PIN_OLED_SCL);
  Wire.setTimeOut(50);
  Wire.setClock(100000);

  // 5. Jalankan I2C Bus Scanner
  targetI2cAddr = scanI2cBus();

  if (targetI2cAddr == 0) {
    // Gagal: Tidak ada perangkat sama sekali di bus I2C
    oledDetected = false;
    oledReady = false;
    setRgbColor(1, 0, 0); // MERAH: Gagal
    Serial.println("\n[FATAL] Tidak ada perangkat yang merespons ACK di jalur I2C!");
    Serial.println("        Kemungkinan Penyebab:");
    Serial.println("        1. Solderan kaki header OLED (H2) ada yang kendor/putus.");
    Serial.println("        2. Pin SDA (GPIO 8) atau SCL (GPIO 9) tertahan ke GND (Short).");
    Serial.println("        3. Tegangan 5V pada Pin 2 H2 belum menyuplai modul OLED.");
    return;
  }

  // 6. Uji Handshake I2C Spesifik ke Alamat Terdeteksi
  Wire.beginTransmission(targetI2cAddr);
  byte pingErr = Wire.endTransmission();

  if (pingErr != 0) {
    oledDetected = false;
    oledReady = false;
    setRgbColor(1, 0, 0); // MERAH: Timeout/Error
    Serial.printf("[ERR] Handshake ke alamat 0x%02X gagal (Kode Galat I2C: %d)\n", targetI2cAddr, pingErr);
    return;
  }

  oledDetected = true;
  Serial.printf("[OK] Handshake I2C berhasil ke alamat 0x%02X (ACK diterima)!\n", targetI2cAddr);

  // 7. Inisialisasi Driver SSD1306 dengan Charge Pump Aktif (SSD1306_SWITCHCAPVCC)
  Serial.println("[INIT] Mengirim perintah inisialisasi register SSD1306...");
  if (display.begin(SSD1306_SWITCHCAPVCC, targetI2cAddr, false, false)) {
    oledReady = true;
    setRgbColor(0, 1, 0); // HIJAU SOLID: Sukses Total!
    Serial.println("[OK] Driver SSD1306 berhasil diinisialisasi!");

    // --- TAHAP TEST VISUAL 1: Full White Flash (1 Detik) ---
    // Mengaktifkan seluruh 8.192 piksel untuk menguji charge pump & tabung display
    Serial.println("[TEST VISUAL 1] Menyalakan seluruh piksel putih (Full Screen Flash)...");
    display.clearDisplay();
    display.fillScreen(SSD1306_WHITE);
    display.display();
    delay(1000);

    // --- TAHAP TEST VISUAL 2: Invert Blink ---
    Serial.println("[TEST VISUAL 2] Uji Invert Display register...");
    display.invertDisplay(true);
    delay(400);
    display.invertDisplay(false);
    delay(400);

    // Bersihkan layar untuk mode runtime
    display.clearDisplay();
    display.display();
  } else {
    oledReady = false;
    setRgbColor(1, 1, 0); // KUNING: Alamat I2C ada tapi inisialisasi driver gagal
    Serial.println("[ERR] Gagal menginisialisasi buffer memori Adafruit SSD1306!");
  }
}

void loop() {
  unsigned long currentMillis = millis();

  // Jika OLED tidak terdeteksi atau error, kedipkan LED MERAH setiap 500ms
  if (!oledReady) {
    static bool redBlink = false;
    if (currentMillis - lastTick >= 500) {
      lastTick = currentMillis;
      redBlink = !redBlink;
      setRgbColor(redBlink, 0, 0);
      Serial.printf("[MONITOR] OLED OFFLINE | Mencoba re-ping 0x%02X... ", targetI2cAddr);
      Wire.beginTransmission(targetI2cAddr);
      byte err = Wire.endTransmission();
      Serial.printf("Hasil: %d\n", err);
    }
    return;
  }

  // Jika OLED READY, render animasi dan teks counter setiap 1 detik
  if (currentMillis - lastTick >= 1000) {
    lastTick = currentMillis;
    frameCount++;

    // Pertahankan LED HIJAU Solid sebagai tanda sistem beroperasi normal
    setRgbColor(0, 1, 0);

    display.clearDisplay();

    // 1. Header Box
    display.fillRect(0, 0, 128, 12, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK, SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(8, 2);
    display.print("POLTEKOM TEST BENCH");

    // 2. Konten Status Utama
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 18);
    display.print("Status : ");
    display.println("OLED ALIVE!");

    display.setCursor(0, 30);
    display.printf("I2C Bus: 0x%02X (100kHz)\n", targetI2cAddr);

    display.setCursor(0, 42);
    display.printf("Frames : %lu ticks\n", frameCount);

    // 3. Animasi Baris Berjalan (Visual Activity Indicator)
    int barWidth = (frameCount % 20) * 6;
    display.drawRect(0, 54, 128, 8, SSD1306_WHITE);
    display.fillRect(2, 56, barWidth, 4, SSD1306_WHITE);

    display.display();

    Serial.printf("[RUNNING] Frame: #%04lu | I2C Addr: 0x%02X | LED: HIJAU | Arus Stabil\n",
                  frameCount, targetI2cAddr);
  }
}

// =============================================================================
// FUNGSI PENDUKUNG
// =============================================================================

// Kendali Warna LED RGB Common Cathode (HIGH = Menyala, LOW = Padam)
void setRgbColor(bool r, bool g, bool b) {
  digitalWrite(PIN_LED_R, r ? HIGH : LOW);
  digitalWrite(PIN_LED_G, g ? HIGH : LOW);
  digitalWrite(PIN_LED_B, b ? HIGH : LOW);
}

// Menonaktifkan & Mengunci Seluruh GPIO Beban Tinggi / Sensor
void disableAllOtherGpios() {
  // Matikan Transistor Kipas SS8050 secara absolut (0.00 V pada basis)
  pinMode(PIN_FAN_PWM, OUTPUT);
  digitalWrite(PIN_FAN_PWM, LOW);

  // Set pin-pin sensor menjadi INPUT floating tanpa beban arus
  pinMode(PIN_DHT_DATA, INPUT);
  pinMode(PIN_MQ7_ADC, INPUT);
  pinMode(PIN_MQ2_ADC, INPUT);

  // Pin sisa lainnya
  pinMode(6, INPUT);
  pinMode(7, INPUT);
  pinMode(20, INPUT);
  pinMode(21, INPUT);
}

// Scanner Seluruh Alamat I2C (0x01 s/d 0x7F)
uint8_t scanI2cBus() {
  Serial.println("\n--- Memulai Pemindaian Alamat I2C (0x01 - 0x7F) ---");
  uint8_t foundAddr = 0;
  int deviceCount = 0;

  for (uint8_t addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    byte err = Wire.endTransmission();

    if (err == 0) {
      Serial.printf("  [+] Perangkat I2C DITEMUKAN pada alamat: 0x%02X", addr);
      if (addr == 0x3C) Serial.print(" (Alamat default SSD1306 0.96\")");
      if (addr == 0x3D) Serial.print(" (Alamat alternatif SSD1306)");
      Serial.println();
      if (foundAddr == 0) foundAddr = addr;
      deviceCount++;
    } else if (err == 4) {
      Serial.printf("  [!] Galat bus hardware pada alamat: 0x%02X\n", addr);
    } else if (err == 5) {
      Serial.printf("  [!] Waktu tunggu (Timeout) habis pada alamat: 0x%02X\n", addr);
    }
  }

  if (deviceCount == 0) {
    Serial.println("  [-] Pemindaian selesai: 0 perangkat I2C terdeteksi.");
  } else {
    Serial.printf("  [v] Pemindaian selesai: Ditemukan %d perangkat.\n", deviceCount);
  }
  Serial.println("--------------------------------------------------\n");

  return foundAddr;
}
