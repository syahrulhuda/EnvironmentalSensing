/*
  =============================================================================
  Environmental Sensing System (ESS) - Production Edge Firmware v5.1
  Bengkel Mekatronika POLTEKOM
  
  Target MCU: ESP32-C3 SuperMini (RISC-V 32-bit Single-Core @ 160MHz)
  Arsitektur: Hybrid FreeRTOS Preemptive Task + Non-blocking millis() Scheduler
              (Pilar 3 & Pilar 5 RULEBOOK Compliant)
  
  Fitur Optimasi v5.1:
    1. FreeRTOS Decoupled Cloud Task (HTTPS POST terisolasi, zero loop-jitter)
    2. Empirical Baseline Calibrated (MQ7: 420 ADC, MQ2: 360 ADC)
    3. 1:1 Cadence Synchronization (Sampling 3s -> Push Cloud 3s via Queue)
    4. 15s Thermal Warmup Shield (Proteksi false alarm & fan screaming saat cold boot)
    5. 8x ADC Hardware Oversampling (Filter peredam ripple daya & derau analog)

  Pinout Resmi Prototype:
    - OLED SSD1306 0.96" I2C : SDA -> GPIO 8, SCL -> GPIO 9 (0x3C, VCC: 5V)
    - DHT22 (AM2302)        : DATA -> GPIO 10 (Pull-up 10k ke 5V, VDD: 5V)
    - MQ-7 (Carbon Monoxide) : AO   -> GPIO 1 (ADC1_CH1, VCC: 5V)
    - MQ-2 (Smoke & Gas)     : AO   -> GPIO 0 (ADC1_CH0, VCC: 5V)
    - LED RGB Common Cathode : RED  -> GPIO 4 (R2 220R)
                               GREEN-> GPIO 3 (R3 220R)
                               BLUE -> GPIO 2 (R4 220R)
                               Cathode -> GND
    - Fan PWM (Low-Side NPN) : PWM  -> GPIO 5 (R5 1k ke Basis SS8050)
    - Power                  : 5V Regulated (Terminal KF301 + Filter C1/C2)

  Petunjuk Arduino IDE 2.x:
    - Board: ESP32C3 Dev Module
    - Flash Mode: DIO (Wajib DIO)
    - USB CDC On Boot: Enabled
    - Upload Speed: 921600 / 115200
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
#include <esp_wifi.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>

// Ambil kredensial rahasia dari tab secrets.h (Pilar 5 RULEBOOK)
#include "secrets.h"

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

#define FAN_PWM_PIN   5     // GPIO 5 - Kendali PWM Kipas Hisap (SS8050 NPN)

// =============================================================================
// 2. STANDAR AMBANG BATAS K3 & KALIBRASI EMPIRIS SENSOR
// =============================================================================
// MQ-7: Karbon Monoksida (CO) dalam satuan PPM
#define MQ7_WARN_PPM   50
#define MQ7_DANGER_PPM 150

// MQ-2: Gas / Asap dalam satuan PPM
#define MQ2_WARN_PPM   150
#define MQ2_DANGER_PPM 400

// Kalibrasi Baseline Empiris Udara Bersih (Data Pengujian Fisik Lab)
#define MQ7_BASELINE_ADC 420   // Nilai idle ADC MQ-7 di udara bersih (~0.34V)
#define MQ2_BASELINE_ADC 360   // Nilai idle ADC MQ-2 di udara bersih (~0.29V)
#define TEMP_OFFSET      0.0   // Offset suhu (°C)

// =============================================================================
// 3. DEFINISI LEVEL DAYA KIPAS PWM (30x30 mm 5V)
// =============================================================================
#define FAN_PWM_STOP   0    // 0%   (0.00V) - Mati Total
#define FAN_PWM_LOW    128  // 50%  (~2.50V) - Mode Normal & Warmup (Senyap, Aman Arus Rel 5V)
#define FAN_PWM_MED    191  // 75%  (~3.75V) - Mode Waspada K3 (Sirkulasi Sedang)
#define FAN_PWM_HIGH   255  // 100% (~5.00V) - Mode Bahaya K3 (Purge Maksimal)

// =============================================================================
// 4. INTERVAL WAKTU NON-BLOCKING & WARMUP SHIELD
// =============================================================================
const unsigned long INTERVAL_SENSOR   = 3000;   // Baca sensor & picu cloud tiap 3 detik (1:1 cadence)
const unsigned long INTERVAL_DISPLAY  = 1000;   // Refresh tampilan OLED tiap 1 detik (Tanpa switching)
const unsigned long INTERVAL_STROBE   = 150;    // Kecepatan kedip LED merah bahaya (ms)
const unsigned long WARMUP_DURATION   = 15000;  // 15 Detik Thermal Warmup Shield untuk koil MQ

// =============================================================================
// 5. STRUKTUR DATA TELEMETRI & FREERTOS
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

  int   fanPwm      = FAN_PWM_LOW;
  float hazardScore = 0.0;
  const char* status = "NORMAL"; // "WARMUP", "NORMAL", "WARNING", "DANGER"
} telemetry;

// Paket Ringkas Thread-Safe untuk FreeRTOS Queue ke Cloud Task
struct TelemetryPacket {
  float temperature;
  float humidity;
  bool  dhtValid;
  int   mq7Raw;
  float mq7Volt;
  int   mq7Ppm;
  int   mq2Raw;
  float mq2Volt;
  int   mq2Ppm;
  int   fanPwm;
  char  status[12];
};

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
DHT dht(DHT_PIN, DHT_TYPE);

// FreeRTOS Handles
QueueHandle_t firebaseQueue      = NULL;
TaskHandle_t  firebaseTaskHandle = NULL;

unsigned long lastSensorRead  = 0;
unsigned long lastDisplayPage = 0;
unsigned long lastStrobeTick  = 0;
unsigned long lastOledRetry   = 0;
unsigned long sampleCount     = 0;

bool oledReady      = false;
bool wifiConnected  = false;
bool strobeState    = false;

// =============================================================================
// 6. PROTOTIPE FUNGSI
// =============================================================================
void initHardware();
void recoverI2CBus();
bool tryInitOled();
void initWiFi();
void readSensors();
void evaluateK3Status();
void setFanPwm(int duty);
void updateRgbIndicator();
void setRgbColor(bool r, bool g, bool b);
void updateOledDisplay();
void drawDashboardScreen();
void logTelemetrySerial();
void sendTelemetryFirebase(const TelemetryPacket &data);
void vFirebaseTask(void *pvParameters);
int  calculateMq7Ppm(int rawAdc);
int  calculateMq2Ppm(int rawAdc);

// =============================================================================
// 7. SETUP UTAMA
// =============================================================================
void setup() {
  Serial.begin(115200);
  delay(500); // Stabilisasi Serial USB CDC

  Serial.println("\n=======================================================");
  Serial.println("  POLTEKOM SMART ENVIRONMENTAL SENSING SYSTEM (ESS)");
  Serial.println("  Edge Node Firmware v5.1 - Optimized Multitasking");
  Serial.println("=======================================================");

  initHardware();
  initWiFi();

  // Inisialisasi FreeRTOS Queue (Kapasitas 1 paket overwrite) & Background Cloud Task
  firebaseQueue = xQueueCreate(1, sizeof(TelemetryPacket));
  if (firebaseQueue != NULL) {
    xTaskCreate(
      vFirebaseTask,
      "FirebaseTask",
      8192,             // 8KB Stack untuk HTTPS TLS mbedTLS
      NULL,
      1,                // Priority 1 (Cooperative dengan loopTask)
      &firebaseTaskHandle
    );
    Serial.println("[FREERTOS] Background Cloud Task berhasil dibuat (8KB Stack, Priority 1).");
  } else {
    Serial.println("[ERROR] Gagal membuat FreeRTOS Queue!");
  }

  // Pembacaan awal sensor & inisialisasi status
  readSensors();
  evaluateK3Status();
  updateOledDisplay();
  logTelemetrySerial();

  Serial.println("[SYSTEM] Setup selesai. Memulai non-blocking main loop...\n");
}

// =============================================================================
// 8. LOOP UTAMA (NON-BLOCKING BASIS MILLIS() - PATUH PILAR 3)
// =============================================================================
void loop() {
  unsigned long currentMillis = millis();

  // 1. Eksekusi Indikator Visual LED RGB Real-Time (Smooth animations)
  updateRgbIndicator();

  // 2. Tugas Rutin A: Sampling Sensor, Evaluasi K3, & Push Telemetri ke Queue (tiap 3 detik)
  if (currentMillis - lastSensorRead >= INTERVAL_SENSOR) {
    lastSensorRead = currentMillis;
    readSensors();
    evaluateK3Status();
    logTelemetrySerial();

    // Salin data ke snapshot thread-safe dan kirim ke FreeRTOS Cloud Task
    if (wifiConnected && firebaseQueue != NULL && strlen(SECRET_FIREBASE_URL) > 0) {
      TelemetryPacket packet;
      packet.temperature = telemetry.temperature;
      packet.humidity    = telemetry.humidity;
      packet.dhtValid    = telemetry.dhtValid;
      packet.mq7Raw      = telemetry.mq7Raw;
      packet.mq7Volt     = telemetry.mq7Volt;
      packet.mq7Ppm      = telemetry.mq7Ppm;
      packet.mq2Raw      = telemetry.mq2Raw;
      packet.mq2Volt     = telemetry.mq2Volt;
      packet.mq2Ppm      = telemetry.mq2Ppm;
      packet.fanPwm      = telemetry.fanPwm;
      strncpy(packet.status, telemetry.status, sizeof(packet.status) - 1);
      packet.status[sizeof(packet.status) - 1] = '\0';

      xQueueOverwrite(firebaseQueue, &packet);
    }
  }

  // 3. Tugas Rutin B: Render Tampilan Layar OLED (Refresh tiap 1 detik tanpa rotasi)
  if (currentMillis - lastDisplayPage >= INTERVAL_DISPLAY) {
    lastDisplayPage = currentMillis;
    updateOledDisplay();
  }

  // 4. Tugas Rutin C: Sinkronisasi Status Wi-Fi (Handled natively by ESP-IDF background)
  if (WiFi.status() == WL_CONNECTED) {
    if (!wifiConnected) {
      wifiConnected = true;
    }
  } else {
    if (wifiConnected) {
      wifiConnected = false;
      Serial.println("\n[WIFI] Sinyal Wi-Fi terputus. Beralih ke Mode Offline...");
    }
  }
}

// =============================================================================
// 9. IMPLEMENTASI MODUL-MODUL FUNGSIONAL
// =============================================================================

// Prosedur pemulihan bus I2C (9 SCL Clock Pulses) jika SDA tertahan LOW oleh slave saat reset
void recoverI2CBus() {
  pinMode(I2C_SDA_PIN, INPUT_PULLUP);
  pinMode(I2C_SCL_PIN, OUTPUT);
  digitalWrite(I2C_SCL_PIN, HIGH);
  delayMicroseconds(10);

  // Jika SDA ditarik LOW oleh slave (misal OLED tertahan di tengah transmisi):
  if (digitalRead(I2C_SDA_PIN) == LOW) {
    Serial.println("[I2C] Bus I2C terkunci (SDA LOW). Menjalankan 9 SCL clock pulses recovery...");
    for (int i = 0; i < 9; i++) {
      digitalWrite(I2C_SCL_PIN, LOW);
      delayMicroseconds(10);
      digitalWrite(I2C_SCL_PIN, HIGH);
      delayMicroseconds(10);
      if (digitalRead(I2C_SDA_PIN) == HIGH) {
        break; // Slave telah melepaskan jalur SDA
      }
    }
    // Kirim sinyal STOP kondisional I2C: SDA LOW -> SCL HIGH -> SDA HIGH
    pinMode(I2C_SDA_PIN, OUTPUT);
    digitalWrite(I2C_SDA_PIN, LOW);
    delayMicroseconds(10);
    digitalWrite(I2C_SCL_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(I2C_SDA_PIN, HIGH);
    delayMicroseconds(10);
    pinMode(I2C_SDA_PIN, INPUT_PULLUP);
  }
}

// Inisialisasi OLED Display SSD1306 (0x3C) dengan I2C Hardware Ping Sejati
bool tryInitOled() {
  Wire.beginTransmission(OLED_I2C_ADDR);
  byte i2cErr = Wire.endTransmission();

  if (i2cErr == 0 && display.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDR, false, false)) {
    oledReady = true;
    // Proteksi pemulihan register: matikan scrolling dan kunci start line di 0
    display.ssd1306_command(SSD1306_DEACTIVATE_SCROLL);
    display.ssd1306_command(SSD1306_SETSTARTLINE | 0x00);
    display.setRotation(0);
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(10, 15);
    display.println("POLTEKOM ESS v5.1");
    display.setCursor(10, 30);
    display.println("Connecting Wi-Fi...");
    display.setCursor(10, 45);
    display.println("Preheating Sensors...");
    display.display();
    Serial.println("[INIT] OLED Display 128x64 Terdeteksi (0x3C).");
    return true;
  } else {
    oledReady = false;
    Serial.printf("[WARN] OLED Display TIDAK terdeteksi di jalur I2C (Kode Error: %d)! Berjalan dalam Mode Headless.\n", i2cErr);
    return false;
  }
}

// --- Modul A: Inisialisasi Perangkat Keras ---
void initHardware() {
  Serial.println("[INIT] Mempersiapkan GPIO, PWM, & Bus I2C...");

  // 1. Konfigurasi Pin LED RGB (Common Cathode)
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_BLUE_PIN, OUTPUT);
  setRgbColor(0, 0, 0);

  // 2. Konfigurasi Driver Kipas PWM (SS8050 NPN) - Pastikan mati sebelum I2C aktif
  pinMode(FAN_PWM_PIN, OUTPUT);
  setFanPwm(FAN_PWM_STOP);

  // 3. Pemulihan & Inisialisasi Bus I2C + Layar OLED (Saat rel daya 5V bersih tanpa beban kipas)
  recoverI2CBus();
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setTimeOut(50);   // Timeout 50ms mencegah lockup strapping pin GPIO 9
  Wire.setClock(100000); // 100 kHz Standard Mode (Stabil & imun derau pada PCB)
  tryInitOled();

  // 4. Swift & Silent Self-Test (< 500ms, RGB Sweep murni tanpa beban kipas)
  Serial.println("[TEST] Uji Mandiri Senyap (RGB Sweep murni, kipas ditahan mati)...");
  setRgbColor(1, 0, 0); delay(150); // Merah
  setRgbColor(0, 1, 0); delay(150); // Hijau
  setRgbColor(0, 0, 1); delay(150); // Biru
  setRgbColor(0, 0, 0);
  // Kipas DITAHAN MATI (0%) sepanjang fase boot & negosiasi Wi-Fi untuk mencegah inrush surge pada rel 5V
  setFanPwm(FAN_PWM_STOP);
  Serial.println("[TEST] Uji Mandiri Selesai.");

  // 5. Inisialisasi Sensor DHT22 & ADC 12-bit
  dht.begin();
  analogReadResolution(12);

  Serial.println("[INIT] Hardware berhasil diinisialisasi.");
}

// Callback Event Wi-Fi untuk mendiagnosa alasan koneksi secara presisi
void onWiFiEvent(WiFiEvent_t event, WiFiEventInfo_t info) {
  switch (event) {
    case ARDUINO_EVENT_WIFI_STA_CONNECTED:
      Serial.println("\n[WIFI EVENT] Sukses terasosiasi ke AP. Meminta alamat IP via DHCP...");
      break;
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      wifiConnected = true;
      Serial.printf("\n[WIFI EVENT] DHCP Berhasil! IP: %s | Gateway: %s\n",
                    WiFi.localIP().toString().c_str(), WiFi.gatewayIP().toString().c_str());
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED: {
      wifiConnected = false;
      uint8_t reason = info.wifi_sta_disconnected.reason;
      Serial.printf("\n[WIFI EVENT] Terputus dari AP (Reason Code: %d)\n", reason);
      break;
    }
    default:
      break;
  }
}

// --- Modul B: Inisialisasi Jaringan Wi-Fi ---
void initWiFi() {
  if (strlen(SECRET_WIFI_SSID) == 0 || strcmp(SECRET_WIFI_SSID, "NAMA_WIFI_ATAU_HOTSPOT_ANDA") == 0) {
    Serial.println("[WIFI] SSID belum dikonfigurasi di secrets.h. Masuk ke Mode Offline.");
    wifiConnected = false;
    return;
  }

  // 1. Daftarkan Event Listener sebelum menyalakan radio
  WiFi.onEvent(onWiFiEvent);

  // 2. Matikan Radio Bluetooth agar 100% kristal RF dialokasikan untuk Wi-Fi
  btStop();

  // 3. Reset state & NVS cache Wi-Fi untuk memastikan inisialisasi bersih
  WiFi.persistent(false);
  WiFi.disconnect(true, true);
  delay(100);

  // 4. Konfigurasi Mode Station
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);              // Matikan power-saving modem Wi-Fi
  WiFi.setTxPower(WIFI_POWER_11dBm); // 11 dBm: aman dari drop tegangan LDO SuperMini
  WiFi.setAutoReconnect(true);       // Native auto-reconnect ESP-IDF di background

  // 5. Force Mode Legacy 802.11b/g/n & WPA2-PSK Murni (Emulasi Karakter ESP32-WROOM)
  esp_wifi_set_protocol(WIFI_IF_STA, WIFI_PROTOCOL_11B | WIFI_PROTOCOL_11G | WIFI_PROTOCOL_11N);

  wifi_config_t conf;
  if (esp_wifi_get_config(WIFI_IF_STA, &conf) == ESP_OK) {
    conf.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
    conf.sta.pmf_cfg.capable = false;
    conf.sta.pmf_cfg.required = false;
    esp_wifi_set_config(WIFI_IF_STA, &conf);
    Serial.println("[WIFI] Mode Legacy WPA2 Diaktifkan (Emulasi WROOM, PMF Nonaktif, TX 11dBm).");
  }

  // 6. Hubungkan ke Access Point
  Serial.printf("[WIFI] Menghubungkan ke AP: \"%s\" ", SECRET_WIFI_SSID);
  WiFi.begin(SECRET_WIFI_SSID, SECRET_WIFI_PASS);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 25) { // 25 x 500ms = 12.5 detik
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.printf("\n[WIFI] Terhubung! IP: %s | RSSI: %d dBm | Gateway: %s\n",
                  WiFi.localIP().toString().c_str(), WiFi.RSSI(), WiFi.gatewayIP().toString().c_str());
  } else {
    wifiConnected = false;
    Serial.printf("\n[WARN] Belum terhubung di setup (Kode: %d). Sistem lanjut berjalan di Mode Offline (Background reconnect aktif).\n", WiFi.status());
  }
}

// --- Modul C: Pembacaan Sensor dengan 8x Hardware Oversampling ---
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

  // 2. 8x Hardware Oversampling untuk Sensor Gas (Filter Derau LDO & Fluktuasi ADC)
  uint32_t mq7Sum = 0;
  uint32_t mq2Sum = 0;
  const int OVERSAMPLE_COUNT = 8;

  for (int i = 0; i < OVERSAMPLE_COUNT; i++) {
    mq7Sum += analogRead(MQ7_ADC_PIN);
    mq2Sum += analogRead(MQ2_ADC_PIN);
    delayMicroseconds(50);
  }

  telemetry.mq7Raw  = mq7Sum / OVERSAMPLE_COUNT;
  telemetry.mq7Volt = ((float)telemetry.mq7Raw / 4095.0) * 3.3;
  telemetry.mq7Ppm  = calculateMq7Ppm(telemetry.mq7Raw);

  telemetry.mq2Raw  = mq2Sum / OVERSAMPLE_COUNT;
  telemetry.mq2Volt = ((float)telemetry.mq2Raw / 4095.0) * 3.3;
  telemetry.mq2Ppm  = calculateMq2Ppm(telemetry.mq2Raw);
}

// --- Modul D: Evaluasi Tingkat Bahaya K3 & Thermal Warmup Shield ---
void evaluateK3Status() {
  // Proteksi Fase Pemanasan (Warmup Shield - 15 Detik Pertama)
  if (millis() < WARMUP_DURATION) {
    telemetry.status = "WARMUP";
    telemetry.fanPwm = FAN_PWM_LOW; // Kipas 50% (~2.5V) halus, senyap, & bebas lonjakan inrush
    telemetry.hazardScore = 0.0;
    // Tahan nilai estimasi PPM pada batas aman saat koil SnO2 menstabilkan suhu
    telemetry.mq7Ppm = 5;
    telemetry.mq2Ppm = 5;
    setFanPwm(telemetry.fanPwm);
    return;
  }

  // Evaluasi Normal K3 setelah sensor stabil
  if (telemetry.mq7Ppm >= MQ7_DANGER_PPM || telemetry.mq2Ppm >= MQ2_DANGER_PPM) {
    telemetry.status = "DANGER";
    telemetry.fanPwm = FAN_PWM_HIGH; // 100% (5.0V Purge Maksimal)
  } else if (telemetry.mq7Ppm >= MQ7_WARN_PPM || telemetry.mq2Ppm >= MQ2_WARN_PPM) {
    telemetry.status = "WARNING";
    telemetry.fanPwm = FAN_PWM_MED;  // 75% (~3.75V Mode Waspada)
  } else {
    telemetry.status = "NORMAL";
    telemetry.fanPwm = FAN_PWM_LOW;  // 50% (~2.5V Sirkulasi Normal Senyap)
  }

  // Terapkan kecepatan kipas ke pin PWM
  setFanPwm(telemetry.fanPwm);

  // Hitung Hazard Priority Score (selaras dengan ETL backend)
  float h_mq7 = (float)telemetry.mq7Ppm / (float)MQ7_WARN_PPM;
  float h_mq2 = (float)telemetry.mq2Ppm / (float)MQ2_WARN_PPM;
  telemetry.hazardScore = (h_mq7 > h_mq2) ? h_mq7 : h_mq2;
}

// --- Modul E: Penggerak Kipas PWM ---
void setFanPwm(int duty) {
  duty = constrain(duty, 0, 255);
  analogWrite(FAN_PWM_PIN, duty);
}

// --- Modul F: Indikator Visual K3 (LED RGB Common Cathode) ---
void setRgbColor(bool r, bool g, bool b) {
  digitalWrite(LED_RED_PIN,   r ? HIGH : LOW);
  digitalWrite(LED_GREEN_PIN, g ? HIGH : LOW);
  digitalWrite(LED_BLUE_PIN,  b ? HIGH : LOW);
}

void updateRgbIndicator() {
  if (millis() < WARMUP_DURATION) {
    // Mode Pemanasan Sensor: Biru Berkedip Halus (Warmup Indication)
    if (millis() - lastStrobeTick >= 500) {
      lastStrobeTick = millis();
      strobeState = !strobeState;
      setRgbColor(false, false, strobeState);
    }
  } else if (strcmp(telemetry.status, "DANGER") == 0) {
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

// --- Modul G: Pembaruan Tampilan Layar OLED 128x64 (Single Clean Dashboard) ---
void updateOledDisplay() {
  // 1. Mekanisme Pemulihan Mandiri (Self-Healing) jika bus I2C sempat glitch/tercabut
  if (!oledReady) {
    unsigned long now = millis();
    if (now - lastOledRetry >= 5000) {
      lastOledRetry = now;
      recoverI2CBus();
      Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
      Wire.setTimeOut(50);
      Wire.setClock(100000);
      if (tryInitOled()) {
        Serial.println("[OLED] Self-healing berhasil! Layar OLED aktif kembali.");
      }
    }
    return;
  }

  // 2. Active Heartbeat Check (Deteksi instan jika kabel kendor / lepas di tengah operasi)
  Wire.beginTransmission(OLED_I2C_ADDR);
  byte i2cErr = Wire.endTransmission();
  if (i2cErr != 0) {
    Serial.printf("[OLED] Koneksi I2C terputus di tengah jalan! (I2C Err: %d). Masuk mode pemulihan...\n", i2cErr);
    oledReady = false;
    lastOledRetry = millis();
    return;
  }

  // 3. Render Dashboard jika koneksi fisik terverifikasi sehat
  display.clearDisplay();
  drawDashboardScreen();
  display.display();
}

// Layar: Dashboard Utama Pemantauan Lingkungan & K3
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
    display.printf("Suhu : %.1f C", telemetry.temperature);
    display.setCursor(76, 14);
    display.printf("RH:%.0f%%", telemetry.humidity);
  } else {
    display.print("Suhu : ERR     RH: ERR");
  }

  // 3. Baris Konsentrasi Gas (CO & Asap) & Counter Paket
  display.setCursor(0, 26);
  display.printf("CO   : %3d ppm", telemetry.mq7Ppm);

  display.setCursor(0, 37);
  display.printf("Asap : %3d ppm", telemetry.mq2Ppm);
  display.setCursor(76, 37);
  display.printf("#%lu", sampleCount);

  // 4. Footer Banner Status K3
  if (millis() < WARMUP_DURATION) {
    unsigned long remainingSec = (WARMUP_DURATION - millis()) / 1000 + 1;
    display.drawRect(0, 50, 128, 14, SSD1306_WHITE);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(14, 53);
    display.printf("[ WARMUP: %02lus ]", remainingSec);
  } else if (strcmp(telemetry.status, "DANGER") == 0) {
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

// --- Modul H: Logging Serial Monitor (115200 Baud) ---
void logTelemetrySerial() {
  char thStr[32];
  if (telemetry.dhtValid) {
    snprintf(thStr, sizeof(thStr), "T:%.1fC H:%.1f%%", telemetry.temperature, telemetry.humidity);
  } else {
    snprintf(thStr, sizeof(thStr), "T:ERR H:ERR");
  }

  if (millis() < WARMUP_DURATION) {
    unsigned long rem = (WARMUP_DURATION - millis()) / 1000 + 1;
    Serial.printf("[ESS #%04lu] %s | MQ7:%3d ppm (ADC:%4d, %.2fV) | MQ2:%3d ppm (ADC:%4d, %.2fV) | K3:WARMUP (%lus) | FAN:%d%%\n",
                  sampleCount, thStr,
                  telemetry.mq7Ppm, telemetry.mq7Raw, telemetry.mq7Volt,
                  telemetry.mq2Ppm, telemetry.mq2Raw, telemetry.mq2Volt,
                  rem, (telemetry.fanPwm * 100) / 255);
  } else {
    Serial.printf("[ESS #%04lu] %s | MQ7:%3d ppm (ADC:%4d, %.2fV) | MQ2:%3d ppm (ADC:%4d, %.2fV) | K3:%s | FAN:%d%%\n",
                  sampleCount, thStr,
                  telemetry.mq7Ppm, telemetry.mq7Raw, telemetry.mq7Volt,
                  telemetry.mq2Ppm, telemetry.mq2Raw, telemetry.mq2Volt,
                  telemetry.status, (telemetry.fanPwm * 100) / 255);
  }
}

// --- Modul I: FreeRTOS Background Cloud Task (Preemptive & Non-blocking) ---
void vFirebaseTask(void *pvParameters) {
  TelemetryPacket packet;
  for (;;) {
    // Block tanpa mengonsumsi siklus CPU sampai ada paket baru di Queue
    if (xQueueReceive(firebaseQueue, &packet, portMAX_DELAY) == pdTRUE) {
      if (WiFi.status() == WL_CONNECTED && strlen(SECRET_FIREBASE_URL) > 0) {
        sendTelemetryFirebase(packet);
      }
    }
  }
}

// Transmisi HTTPS REST ke Firebase Realtime Database Buffer
void sendTelemetryFirebase(const TelemetryPacket &data) {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  WiFiClientSecure client;
  client.setInsecure(); // Efisiensi RAM & CPU ESP32-C3
  client.setTimeout(4000);

  HTTPClient https;
  if (https.begin(client, SECRET_FIREBASE_URL)) {
    https.addHeader("Content-Type", "application/json");

#if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
#else
    StaticJsonDocument<384> doc;
#endif
    doc["node_id"]   = DEVICE_NODE_ID;
    if (data.dhtValid) {
      doc["temp"]    = round(data.temperature * 10.0) / 10.0;
      doc["hum"]     = round(data.humidity * 10.0) / 10.0;
    } else {
      doc["temp"]    = nullptr;
      doc["hum"]     = nullptr;
    }
    doc["mq7_raw"]   = data.mq7Raw;
    doc["mq7_volt"]  = round(data.mq7Volt * 100.0) / 100.0;
    doc["mq7_ppm"]   = data.mq7Ppm;

    doc["mq2_raw"]   = data.mq2Raw;
    doc["mq2_volt"]  = round(data.mq2Volt * 100.0) / 100.0;
    doc["mq2_ppm"]   = data.mq2Ppm;

    doc["fan_pwm"]   = (data.fanPwm * 100) / 255;
    doc["status"]    = data.status;
    doc["created_at"][".sv"] = "timestamp";

    String payload;
    serializeJson(doc, payload);

    int httpCode = https.POST(payload);
    if (httpCode >= 200 && httpCode < 300) {
      Serial.printf("  [FIREBASE POST] HTTP %d (Success)\n", httpCode);
    } else if (httpCode > 0) {
      Serial.printf("  [FIREBASE REJECTED] HTTP %d (Unauthorized/Error)\n", httpCode);
    } else {
      Serial.printf("  [FIREBASE ERROR] Gagal mengirim: %s\n", https.errorToString(httpCode).c_str());
    }
    https.end();
  }
}

// --- Modul J: Estimasi Kurva PPM Sensor Gas ---
// MQ-7: Karbon Monoksida (CO) dengan Kalibrasi Baseline Empiris
int calculateMq7Ppm(int rawAdc) {
  int constrainedAdc = constrain(rawAdc, MQ7_BASELINE_ADC, 4095);
  return map(constrainedAdc, MQ7_BASELINE_ADC, 4095, 5, 400);
}

// MQ-2: Gas / Asap dengan Kalibrasi Baseline Empiris
int calculateMq2Ppm(int rawAdc) {
  int constrainedAdc = constrain(rawAdc, MQ2_BASELINE_ADC, 4095);
  return map(constrainedAdc, MQ2_BASELINE_ADC, 4095, 5, 1000);
}
