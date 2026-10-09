/*
  =============================================================================
  Environmental Sensing System (ESS) - Edge Firmware v5 (Breadboard Edition)
  Bengkel Mekatronika POLTEKOM
  
  Target MCU: ESP32-C3 SuperMini (RISC-V 32-bit Single-Core)
  Arsitektur: Non-blocking millis() Scheduler (Pilar 3 RULEBOOK)
  Kredensial : Isolated in secrets.h (Pilar 5 RULEBOOK)
  
  Pinout Sesuai Breadboard Prototype (cobabaru.fzz):
    - OLED SSD1306 0.96" I2C : SDA -> GPIO 8, SCL -> GPIO 9 (VCC: 5V, GND: GND)
    - DHT22 (AM2302)        : DATA -> GPIO 10 (Pull-up 10k ke 3.3V, VDD: 3.3V)
    - MQ-7 (Carbon Monoxide) : AO   -> GPIO 1 (ADC1_CH1, VCC: 5V)
    - MQ-2 (Smoke & Gas)     : AO   -> GPIO 0 (ADC1_CH0, VCC: 5V)
    - LED RGB Common Cathode : RED  -> GPIO 4 (R2 220R)
                               GREEN-> GPIO 3 (R3 220R)
                               BLUE -> GPIO 2 (R4 220R)
                               Cathode -> GND
    - Fan PWM (CN1)          : GPIO 5 (Belum terpasang di breadboard - Standby)
    - Power                  : 100% ESP32 USB-C 5V VBUS (Jack 5V belum dipasang)
  =============================================================================
*/

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <ArduinoJson.h>

// Ambil kredensial dari secrets.h (Pilar 5: Zero Hardcoded Secrets)
#if __has_include("secrets.h")
  #include "secrets.h"
#else
  #define SECRET_WIFI_SSID    ""
  #define SECRET_WIFI_PASS    ""
  #define SECRET_FIREBASE_URL ""
  #define DEVICE_NODE_ID      "NODE-MRS01"
#endif

// =============================================================================
// 1. KONFIGURASI PIN & PERIPHERAL
// =============================================================================
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define OLED_I2C_ADDR 0x3C

#define I2C_SDA_PIN   8
#define I2C_SCL_PIN   9

#define DHT_PIN       10
#define DHT_TYPE      DHT22

#define MQ7_ADC_PIN   1     // GPIO 1 (ADC1_CH1) - Sensor Karbon Monoksida (CO)
#define MQ2_ADC_PIN   0     // GPIO 0 (ADC1_CH0) - Sensor Asap & Gas Mudah Terbakar

#define LED_RED_PIN   4     // GPIO 4 - Kanal Merah LED RGB
#define LED_GREEN_PIN 3     // GPIO 3 - Kanal Hijau LED RGB
#define LED_BLUE_PIN  2     // GPIO 2 - Kanal Biru LED RGB

#define FAN_PWM_PIN   5     // GPIO 5 - Standby (Kipas belum dipasang di breadboard)

// =============================================================================
// 2. STANDAR AMBANG BATAS K3 (Pilar 1 & Solusi TD-H01)
// =============================================================================
// MQ-7: Karbon Monoksida (CO) dalam satuan PPM
#define MQ7_WARN_PPM   50
#define MQ7_DANGER_PPM 150

// MQ-2: Gas / Asap dalam satuan PPM
#define MQ2_WARN_PPM   150
#define MQ2_DANGER_PPM 400

// --- KALIBRASI BASELINE UDARA BERSIH (CLEAN AIR ADC) & OFFSET SUHU ---
#define MQ7_BASELINE_ADC 1550  // Nilai idle ADC MQ-7 di udara bersih (~1.25V)
#define MQ2_BASELINE_ADC 460   // Nilai idle ADC MQ-2 di udara bersih (~0.37V)
#define TEMP_OFFSET      0.0   // Offset suhu (°C). Jika terpengaruh panas heater MQ, ubah misal: -3.0

// =============================================================================
// 3. INTERVAL WAKTU NON-BLOCKING (MILLIS)
// =============================================================================
const unsigned long INTERVAL_SENSOR   = 3000;   // Baca DHT22 & gas tiap 3 detik
const unsigned long INTERVAL_DISPLAY  = 3500;   // Rotasi halaman OLED tiap 3.5 detik
const unsigned long INTERVAL_CLOUD    = 10000;  // Kirim data ke cloud tiap 10 detik
const unsigned long INTERVAL_STROBE   = 150;    // Kecepatan kedip LED merah bahaya

// =============================================================================
// 4. STRUKTUR DATA & OBJEK GLOBAL
// =============================================================================
struct TelemetryData {
  float temperature = 0.0;
  float humidity    = 0.0;
  bool  dhtValid    = false;

  int   mq7Raw      = 0;
  float mq7Volt     = 0.0;
  int   mq7Ppm      = 0;

  int   mq2Raw      = 0;
  float mq2Volt     = 0.0;
  int   mq2Ppm      = 0;

  float hazardScore = 0.0;
  const char* status = "NORMAL"; // "NORMAL", "WARNING", "DANGER"
} telemetry;

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
DHT dht(DHT_PIN, DHT_TYPE);

unsigned long lastSensorRead  = 0;
unsigned long lastDisplayPage = 0;
unsigned long lastCloudPost   = 0;
unsigned long lastStrobeTick  = 0;
unsigned long sampleCount     = 0;

int  oledPage       = 0;        // 0 = Dashboard Utama, 1 = Diagnostik ADC
bool oledReady      = false;
bool wifiConnected  = false;
bool strobeState    = false;

// =============================================================================
// 5. PROTOTIPE FUNGSI
// =============================================================================
void initHardware();
void initWiFi();
void readSensors();
void evaluateK3Status();
void updateRgbIndicator();
void setRgbColor(bool r, bool g, bool b);
void updateOledDisplay();
void drawDashboardScreen();
void drawDiagnosticScreen();
void logTelemetrySerial();
void sendTelemetryFirebase();
int  calculateMq7Ppm(int rawAdc);
int  calculateMq2Ppm(int rawAdc);

// =============================================================================
// 6. SETUP UTAMA
// =============================================================================
void setup() {
  Serial.begin(115200);
  delay(500); // Stabilisasi Serial USB

  Serial.println("\n=======================================================");
  Serial.println("  POLTEKOM SMART ENVIRONMENTAL SENSING SYSTEM (ESS)");
  Serial.println("  Edge Node Firmware v5 - Breadboard Test Build");
  Serial.println("=======================================================");

  initHardware();
  initWiFi();

  // Pembacaan awal sensor
  readSensors();
  evaluateK3Status();
  updateOledDisplay();
  logTelemetrySerial();

  Serial.println("[SYSTEM] Setup selesai. Memulai non-blocking main loop...\n");
}

// =============================================================================
// 7. LOOP UTAMA (NON-BLOCKING BASIS MILLIS() - PATUH PILAR 3)
// =============================================================================
void loop() {
  unsigned long currentMillis = millis();

  // 1. Eksekusi Indikator Visual LED RGB Real-Time
  updateRgbIndicator();

  // 2. Tugas Rutin A: Sampling Sensor & Evaluasi K3 (tiap 3 detik)
  if (currentMillis - lastSensorRead >= INTERVAL_SENSOR) {
    lastSensorRead = currentMillis;
    readSensors();
    evaluateK3Status();
    logTelemetrySerial();
    updateOledDisplay();
  }

  // 3. Tugas Rutin B: Rotasi Tampilan Layar OLED (tiap 3.5 detik)
  if (currentMillis - lastDisplayPage >= INTERVAL_DISPLAY) {
    lastDisplayPage = currentMillis;
    if (strcmp(telemetry.status, "DANGER") != 0) {
      oledPage = (oledPage == 0) ? 1 : 0;
    } else {
      oledPage = 0; // Kunci pada Dashboard Utama jika kondisi BAHAYA
    }
    updateOledDisplay();
  }

  // 4. Tugas Rutin C: Pengiriman Data Telemetri Cloud (tiap 10 detik, jika online)
  if (currentMillis - lastCloudPost >= INTERVAL_CLOUD) {
    lastCloudPost = currentMillis;
    if (wifiConnected && strlen(SECRET_FIREBASE_URL) > 0) {
      sendTelemetryFirebase();
    }
  }
}

// =============================================================================
// 8. IMPLEMENTASI MODUL-MODUL FUNGSIONAL
// =============================================================================

// --- Modul A: Inisialisasi Perangkat Keras ---
void initHardware() {
  Serial.println("[INIT] Mempersiapkan I2C, GPIO, & Sensor...");

  // Konfigurasi Pin LED RGB (Common Cathode)
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_BLUE_PIN, OUTPUT);
  setRgbColor(0, 0, 1); // Warna Biru saat bootloader/inisialisasi

  // Fan Pin standby (Output LOW agar aman jika tercolok)
  pinMode(FAN_PWM_PIN, OUTPUT);
  digitalWrite(FAN_PWM_PIN, LOW);

  // Inisialisasi I2C Bus pada GPIO 8 (SDA) dan GPIO 9 (SCL)
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setClock(400000); // 400 kHz Fast-Mode I2C

  // Inisialisasi OLED Display SSD1306
  if (display.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDR)) {
    oledReady = true;
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(10, 15);
    display.println("POLTEKOM ESS v5");
    display.setCursor(10, 30);
    display.println("Breadboard Test");
    display.setCursor(10, 45);
    display.println("Booting System...");
    display.display();
    Serial.println("[INIT] OLED Display 128x64 Terdeteksi (0x3C).");
  } else {
    Serial.println("[ERROR] OLED Display gagal terdeteksi! Periksa jalur SDA/SCL.");
  }

  // Inisialisasi Sensor DHT22
  dht.begin();

  // Konfigurasi Resolusi ADC 12-bit ESP32-C3 (0 - 4095)
  analogReadResolution(12);

  Serial.println("[INIT] Hardware berhasil diinisialisasi.");
}

// --- Modul B: Inisialisasi Jaringan Wi-Fi ---
void initWiFi() {
  if (strlen(SECRET_WIFI_SSID) == 0 || strcmp(SECRET_WIFI_SSID, "NAMA_WIFI_ATAU_HOTSPOT_ANDA") == 0) {
    Serial.println("[WIFI] SSID belum dikonfigurasi di secrets.h. Masuk ke Mode Offline.");
    wifiConnected = false;
    return;
  }

  Serial.printf("[WIFI] Menyambungkan ke AP: %s ", SECRET_WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(SECRET_WIFI_SSID, SECRET_WIFI_PASS);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 15) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.printf("\n[WIFI] Terhubung! IP: %s | RSSI: %d dBm\n",
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
  } else {
    wifiConnected = false;
    Serial.println("\n[WARN] Timeout koneksi Wi-Fi. Berjalan di Mode Offline Lokal.");
  }
}

// --- Modul C: Pembacaan Sensor Lingkungan & Gas ---
void readSensors() {
  sampleCount++;

  // 1. Baca DHT22 (Suhu & Kelembapan dengan kompensasi suhu)
  float h = dht.readHumidity();
  float rawT = dht.readTemperature();

  if (isnan(h) || isnan(rawT)) {
    telemetry.dhtValid = false;
  } else {
    telemetry.temperature = rawT + TEMP_OFFSET;
    telemetry.humidity    = h;
    telemetry.dhtValid    = true;
  }

  // 2. Baca MQ-7 (Karbon Monoksida - GPIO 1)
  telemetry.mq7Raw  = analogRead(MQ7_ADC_PIN);
  telemetry.mq7Volt = ((float)telemetry.mq7Raw / 4095.0) * 3.3;
  telemetry.mq7Ppm  = calculateMq7Ppm(telemetry.mq7Raw);

  // 3. Baca MQ-2 (Asap & Gas Mudah Terbakar - GPIO 0)
  telemetry.mq2Raw  = analogRead(MQ2_ADC_PIN);
  telemetry.mq2Volt = ((float)telemetry.mq2Raw / 4095.0) * 3.3;
  telemetry.mq2Ppm  = calculateMq2Ppm(telemetry.mq2Raw);
}

// --- Modul D: Evaluasi Tingkat Bahaya K3 ---
void evaluateK3Status() {
  if (telemetry.mq7Ppm >= MQ7_DANGER_PPM || telemetry.mq2Ppm >= MQ2_DANGER_PPM) {
    telemetry.status = "DANGER";
  } else if (telemetry.mq7Ppm >= MQ7_WARN_PPM || telemetry.mq2Ppm >= MQ2_WARN_PPM) {
    telemetry.status = "WARNING";
  } else {
    telemetry.status = "NORMAL";
  }

  // Hitung Hazard Priority Score (selaras dengan ETL backend)
  float h_mq7 = (float)telemetry.mq7Ppm / (float)MQ7_WARN_PPM;
  float h_mq2 = (float)telemetry.mq2Ppm / (float)MQ2_WARN_PPM;
  telemetry.hazardScore = (h_mq7 > h_mq2) ? h_mq7 : h_mq2;
}

// --- Modul E: Indikator Visual K3 (LED RGB Common Cathode) ---
void setRgbColor(bool r, bool g, bool b) {
  digitalWrite(LED_RED_PIN,   r ? HIGH : LOW);
  digitalWrite(LED_GREEN_PIN, g ? HIGH : LOW);
  digitalWrite(LED_BLUE_PIN,  b ? HIGH : LOW);
}

void updateRgbIndicator() {
  if (strcmp(telemetry.status, "DANGER") == 0) {
    // KONDISI BAHAYA: Merah Berkedip Cepat (Strobe 150 ms)
    if (millis() - lastStrobeTick >= INTERVAL_STROBE) {
      lastStrobeTick = millis();
      strobeState = !strobeState;
      setRgbColor(strobeState, false, false);
    }
  } else if (strcmp(telemetry.status, "WARNING") == 0) {
    // KONDISI WASPADA: Kuning Solid (Merah + Hijau)
    setRgbColor(true, true, false);
  } else {
    // KONDISI AMAN / NORMAL: Hijau Solid
    setRgbColor(false, true, false);
  }
}

// --- Modul F: Pembaruan Tampilan Layar OLED 128x64 ---
void updateOledDisplay() {
  if (!oledReady) return;

  display.clearDisplay();

  if (oledPage == 0) {
    drawDashboardScreen();
  } else {
    drawDiagnosticScreen();
  }

  display.display();
}

// Layar 1: Dashboard Utama Pemantauan
void drawDashboardScreen() {
  // 1. Top Header Bar
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("POLTEKOM ESS");

  // Status Konektivitas
  display.setCursor(85, 0);
  if (wifiConnected) {
    display.print("[WIFI]");
  } else {
    display.print("[OFFL]");
  }
  display.drawFastHLine(0, 10, 128, SSD1306_WHITE);

  // 2. Baris Suhu & Kelembaban
  display.setCursor(0, 14);
  if (telemetry.dhtValid) {
    display.printf("Suhu : %.1f C\n", telemetry.temperature);
    display.setCursor(72, 14);
    display.printf("RH: %.1f%%", telemetry.humidity);
  } else {
    display.print("Suhu : --.- C  RH: --%");
  }

  // 3. Baris Konsentrasi Gas
  display.setCursor(0, 26);
  display.printf("CO   : %3d ppm", telemetry.mq7Ppm);
  
  display.setCursor(0, 37);
  display.printf("Asap : %3d ppm", telemetry.mq2Ppm);

  // 4. Footer Banner Status K3
  if (strcmp(telemetry.status, "DANGER") == 0) {
    // Solid White Banner dengan Tulisan Hitam (Emergency Alert)
    display.fillRect(0, 50, 128, 14, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK, SSD1306_WHITE);
    display.setCursor(14, 53);
    display.print("! BAHAYA K3 !");
  } else if (strcmp(telemetry.status, "WARNING") == 0) {
    display.drawRect(0, 50, 128, 14, SSD1306_WHITE);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(18, 53);
    display.print("* WASPADA K3 *");
  } else {
    display.drawRect(0, 50, 128, 14, SSD1306_WHITE);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(22, 53);
    display.print("[ STATUS AMAN ]");
  }
}

// Layar 2: Diagnostik Teknis & ADC Raw
void drawDiagnosticScreen() {
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("DIAGNOSTIK RAW ADC");
  display.drawFastHLine(0, 10, 128, SSD1306_WHITE);

  display.setCursor(0, 14);
  display.printf("MQ7 (CO)  : %4d ADC", telemetry.mq7Raw);
  display.setCursor(0, 25);
  display.printf("Voltase   : %.2f Volt", telemetry.mq7Volt);

  display.setCursor(0, 37);
  display.printf("MQ2 (Asap): %4d ADC", telemetry.mq2Raw);
  display.setCursor(0, 48);
  display.printf("Voltase   : %.2f Volt", telemetry.mq2Volt);

  display.setCursor(0, 57);
  display.printf("Sampel #%lu", sampleCount);
}

// --- Modul G: Logging Serial Monitor (115200 Baud) ---
void logTelemetrySerial() {
  char thStr[32];
  if (telemetry.dhtValid) {
    snprintf(thStr, sizeof(thStr), "T: %.1f C | H: %.1f %%", telemetry.temperature, telemetry.humidity);
  } else {
    snprintf(thStr, sizeof(thStr), "T: ERR | H: ERR");
  }

  Serial.printf("[ESS #%04lu] %s | MQ7: %3d PPM (ADC %4d, %.2fV) | MQ2: %3d PPM (ADC %4d, %.2fV) | K3: %s\n",
                sampleCount, thStr,
                telemetry.mq7Ppm, telemetry.mq7Raw, telemetry.mq7Volt,
                telemetry.mq2Ppm, telemetry.mq2Raw, telemetry.mq2Volt,
                telemetry.status);
}

// --- Modul H: Pengiriman Telemetri ke Firebase RTDB (HTTPS REST) ---
void sendTelemetryFirebase() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  WiFiClientSecure client;
  client.setInsecure(); // Bypass verifikasi sertifikat SSL untuk efisiensi RAM ESP32
  client.setTimeout(4000);

  HTTPClient https;
  if (https.begin(client, SECRET_FIREBASE_URL)) {
    https.addHeader("Content-Type", "application/json");

    StaticJsonDocument<384> doc;
    doc["node_id"]   = DEVICE_NODE_ID;
    if (telemetry.dhtValid) {
      doc["temp"]    = round(telemetry.temperature * 10.0) / 10.0;
      doc["hum"]     = round(telemetry.humidity * 10.0) / 10.0;
    } else {
      doc["temp"]    = nullptr;
      doc["hum"]     = nullptr;
    }
    doc["mq7_raw"]   = telemetry.mq7Raw;
    doc["mq7_volt"]  = round(telemetry.mq7Volt * 100.0) / 100.0;
    doc["mq7_ppm"]   = telemetry.mq7Ppm;

    doc["mq2_raw"]   = telemetry.mq2Raw;
    doc["mq2_volt"]  = round(telemetry.mq2Volt * 100.0) / 100.0;
    doc["mq2_ppm"]   = telemetry.mq2Ppm;

    doc["status"]    = telemetry.status;
    doc["created_at"][".sv"] = "timestamp";

    String payload;
    serializeJson(doc, payload);

    int httpCode = https.POST(payload);
    if (httpCode > 0) {
      Serial.printf("  [CLOUD POST] HTTP %d (Success)\n", httpCode);
    } else {
      Serial.printf("  [CLOUD ERROR] Gagal mengirim: %s\n", https.errorToString(httpCode).c_str());
    }
    https.end();
  }
}

// --- Modul I: Estimasi Kurva PPM Sensor Gas ---
// MQ-7: Karbon Monoksida (CO) dengan Kalibrasi Baseline Udara Bersih
int calculateMq7Ppm(int rawAdc) {
  int constrainedAdc = constrain(rawAdc, MQ7_BASELINE_ADC, 4095);
  return map(constrainedAdc, MQ7_BASELINE_ADC, 4095, 5, 400);
}

// MQ-2: Gas / Asap dengan Kalibrasi Baseline Udara Bersih
int calculateMq2Ppm(int rawAdc) {
  int constrainedAdc = constrain(rawAdc, MQ2_BASELINE_ADC, 4095);
  return map(constrainedAdc, MQ2_BASELINE_ADC, 4095, 5, 1000);
}
