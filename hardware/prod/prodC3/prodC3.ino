/*
  =============================================================================
  Environmental Sensing System (ESS) - Production Edge Firmware v5
  Bengkel Mekatronika POLTEKOM
  
  Target MCU: ESP32-C3 SuperMini (RISC-V 32-bit Single-Core)
  Arsitektur: Non-blocking millis() Scheduler (Pilar 3 RULEBOOK)
  Kredensial : Isolated in secrets.h (Pilar 5 RULEBOOK)
  
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

// Ambil kredensial dari tab secrets.h
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
// 2. STANDAR AMBANG BATAS K3 & KALIBRASI SENSOR
// =============================================================================
// MQ-7: Karbon Monoksida (CO) dalam satuan PPM
#define MQ7_WARN_PPM   50
#define MQ7_DANGER_PPM 150

// MQ-2: Gas / Asap dalam satuan PPM
#define MQ2_WARN_PPM   150
#define MQ2_DANGER_PPM 400

// Kalibrasi Baseline Udara Bersih (Clean Air Zero Reference) & Offset Suhu
#define MQ7_BASELINE_ADC 1550  // Nilai idle ADC MQ-7 di udara bersih (~1.25V)
#define MQ2_BASELINE_ADC 460   // Nilai idle ADC MQ-2 di udara bersih (~0.37V)
#define TEMP_OFFSET      0.0   // Offset suhu (°C). Jika terpengaruh panas koil MQ, ubah misal: -3.0

// =============================================================================
// 3. DEFINISI LEVEL DAYA KIPAS PWM (30x30 mm 5V)
// =============================================================================
#define FAN_PWM_STOP   0    // 0%   (0.00V) - Mati
#define FAN_PWM_LOW    191  // 75%  (~3.70V) - Mode Senyap / Sirkulasi Normal
#define FAN_PWM_MED    230  // 90%  (~4.50V) - Mode Sedang / Waspada
#define FAN_PWM_HIGH   255  // 100% (~4.95V) - Mode Purge Maksimal / Bahaya

// =============================================================================
// 4. INTERVAL WAKTU NON-BLOCKING (MILLIS)
// =============================================================================
const unsigned long INTERVAL_SENSOR   = 3000;   // Baca DHT22 & gas tiap 3 detik
const unsigned long INTERVAL_DISPLAY  = 3500;   // Rotasi halaman OLED tiap 3.5 detik
const unsigned long INTERVAL_CLOUD    = 10000;  // Kirim data ke Firebase tiap 10 detik
const unsigned long INTERVAL_STROBE   = 150;    // Kecepatan kedip LED merah bahaya

// =============================================================================
// 5. STRUKTUR DATA & OBJEK GLOBAL
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
  const char* status = "NORMAL"; // "NORMAL", "WARNING", "DANGER"
} telemetry;

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
DHT dht(DHT_PIN, DHT_TYPE);

const unsigned long INTERVAL_WIFI_RETRY = 12000; // Coba reconnect tiap 12 detik jika offline
unsigned long lastSensorRead  = 0;
unsigned long lastDisplayPage = 0;
unsigned long lastCloudPost   = 0;
unsigned long lastStrobeTick  = 0;
unsigned long lastWifiRetry   = 0;
unsigned long sampleCount     = 0;

int  oledPage       = 0;        // 0 = Dashboard Utama, 1 = Diagnostik ADC
bool oledReady      = false;
bool wifiConnected  = false;
bool strobeState    = false;

// =============================================================================
// 6. PROTOTIPE FUNGSI
// =============================================================================
void initHardware();
void initWiFi();
void readSensors();
void evaluateK3Status();
void setFanPwm(int duty);
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
// 7. SETUP UTAMA
// =============================================================================
void setup() {
  Serial.begin(115200);
  delay(500); // Stabilisasi Serial USB

  Serial.println("\n=======================================================");
  Serial.println("  POLTEKOM SMART ENVIRONMENTAL SENSING SYSTEM (ESS)");
  Serial.println("  Edge Node Firmware v5 - Production Release Build");
  Serial.println("=======================================================");

  initHardware();
  initWiFi();

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
  
    // 5. Tugas Rutin D: Sinkronisasi Status Wi-Fi (Auto-reconnect ditangani native oleh ESP-IDF)
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

// --- Modul A: Inisialisasi Perangkat Keras ---
void initHardware() {
  Serial.println("[INIT] Mempersiapkan GPIO, PWM, & Bus I2C...");

  // 1. Konfigurasi Pin LED RGB (Common Cathode)
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_BLUE_PIN, OUTPUT);
  setRgbColor(0, 0, 0);

  // 2. Konfigurasi Driver Kipas PWM (SS8050 NPN)
  pinMode(FAN_PWM_PIN, OUTPUT);
  setFanPwm(FAN_PWM_STOP);

  // 3. Self-Test Diagnostik LED & Driver Kipas (Bertahap)
  Serial.println("[TEST] Uji Mandiri LED & Kipas PWM...");
  
  // Tahap 1: Hijau + Fan 75%
  setRgbColor(0, 1, 0);
  setFanPwm(FAN_PWM_LOW);
  delay(1200);

  // Tahap 2: Kuning + Fan 90%
  setRgbColor(1, 1, 0);
  setFanPwm(FAN_PWM_MED);
  delay(1200);

  // Tahap 3: Merah + Fan 100%
  setRgbColor(1, 0, 0);
  setFanPwm(FAN_PWM_HIGH);
  delay(1200);

  // Tahap 4: Biru Standby
  setRgbColor(0, 0, 1);
  setFanPwm(FAN_PWM_STOP); // Matikan kipas agar jalur daya 5V bebas ripple selama boot & WiFi
  delay(800);

  setRgbColor(0, 0, 0);
  Serial.println("[TEST] Uji Mandiri Selesai.");

  // 4. Inisialisasi I2C Bus dengan Proteksi Timeout Anti-Freeze
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setTimeOut(50);   // Timeout 50ms mencegah lockup strapping pin GPIO 9
  Wire.setClock(400000); // 400 kHz Fast-Mode I2C

  // 5. Inisialisasi OLED Display SSD1306 (0x3C)
  if (display.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDR, false, false)) {
    oledReady = true;
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(10, 15);
    display.println("POLTEKOM ESS v5");
    display.setCursor(10, 30);
    display.println("Connecting Wi-Fi...");
    display.setCursor(10, 45);
    display.println("Booting System...");
    display.display();
    Serial.println("[INIT] OLED Display 128x64 Terdeteksi (0x3C).");
  } else {
    Serial.println("[ERROR] OLED Display gagal terdeteksi! Periksa jalur SDA(8)/SCL(9).");
  }

  // 6. Inisialisasi Sensor DHT22 & ADC 12-bit
  dht.begin();
  analogReadResolution(12);

  Serial.println("[INIT] Hardware berhasil diinisialisasi.");
}

// Callback Event Wi-Fi untuk mendiagnosa alasan kegagalan koneksi secara presisi
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
      Serial.printf("\n[WIFI EVENT] Terputus dari AP (Alasan / Reason Code: %d)\n", reason);
      if (reason == 202) {
        Serial.println("  -> [DIAGNOSTIK PASTI] Password salah / ditolak oleh router! Periksa huruf besar/kecil.");
      } else if (reason == 15) {
        Serial.println("  -> [DIAGNOSTIK PASTI] 4-Way Handshake Timeout (Fitur PMF/WPA3 pada router Wi-Fi 6 menolak WPA2).");
      } else if (reason == 2) {
        Serial.println("  -> [DIAGNOSTIK PASTI] Auth Expired: Router memutus sesi otentikasi.");
      } else if (reason == 36) {
        Serial.println("  -> [DIAGNOSTIK PASTI] Cipher Suite / PMF Rejected oleh Router.");
      } else if (reason == 201) {
        Serial.println("  -> [DIAGNOSTIK PASTI] AP tidak ditemukan.");
      }
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
  // Menghindari bentrok negosiasi PMF / Wi-Fi 6 GCMP pada router enterprise kampus
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

// --- Modul D: Evaluasi Tingkat Bahaya K3 & Kontrol Kipas ---
void evaluateK3Status() {
  if (telemetry.mq7Ppm >= MQ7_DANGER_PPM || telemetry.mq2Ppm >= MQ2_DANGER_PPM) {
    telemetry.status = "DANGER";
    telemetry.fanPwm = FAN_PWM_HIGH; // 100% (5.0V Purge)
  } else if (telemetry.mq7Ppm >= MQ7_WARN_PPM || telemetry.mq2Ppm >= MQ2_WARN_PPM) {
    telemetry.status = "WARNING";
    telemetry.fanPwm = FAN_PWM_MED;  // 90% (~4.5V Sedang)
  } else {
    telemetry.status = "NORMAL";
    telemetry.fanPwm = FAN_PWM_LOW;  // 75% (~3.7V Senyap)
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

// --- Modul G: Pembaruan Tampilan Layar OLED 128x64 ---
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
    display.printf("Suhu : %.1f C", telemetry.temperature);
    display.setCursor(76, 14);
    display.printf("RH:%.0f%%", telemetry.humidity);
  } else {
    display.print("Suhu : ERR     RH: ERR");
  }

  // 3. Baris Konsentrasi Gas & Kipas
  display.setCursor(0, 26);
  display.printf("CO   : %3d ppm", telemetry.mq7Ppm);
  display.setCursor(76, 26);
  display.printf("Fan:%2d%%", (telemetry.fanPwm * 100) / 255);
  
  display.setCursor(0, 37);
  display.printf("Asap : %3d ppm", telemetry.mq2Ppm);

  // 4. Footer Banner Status K3
  if (strcmp(telemetry.status, "DANGER") == 0) {
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
  display.printf("#%lu | Kipas: %d%%", sampleCount, (telemetry.fanPwm * 100) / 255);
}

// --- Modul H: Logging Serial Monitor (115200 Baud) ---
void logTelemetrySerial() {
  char thStr[32];
  if (telemetry.dhtValid) {
    snprintf(thStr, sizeof(thStr), "T:%.1fC H:%.1f%%", telemetry.temperature, telemetry.humidity);
  } else {
    snprintf(thStr, sizeof(thStr), "T:ERR H:ERR");
  }

  Serial.printf("[ESS #%04lu] %s | MQ7:%3d ppm (ADC:%4d, %.2fV) | MQ2:%3d ppm (ADC:%4d, %.2fV) | K3:%s | FAN:%d%%\n",
                sampleCount, thStr,
                telemetry.mq7Ppm, telemetry.mq7Raw, telemetry.mq7Volt,
                telemetry.mq2Ppm, telemetry.mq2Raw, telemetry.mq2Volt,
                telemetry.status, (telemetry.fanPwm * 100) / 255);
}

// --- Modul I: Pengiriman Telemetri ke Firebase RTDB (HTTPS REST) ---
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

#if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
#else
    StaticJsonDocument<384> doc;
#endif
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

    doc["fan_pwm"]   = (telemetry.fanPwm * 100) / 255;
    doc["status"]    = telemetry.status;
    doc["created_at"][".sv"] = "timestamp";

    String payload;
    serializeJson(doc, payload);

    int httpCode = https.POST(payload);
    if (httpCode > 0) {
      Serial.printf("  [FIREBASE POST] HTTP %d (Success)\n", httpCode);
    } else {
      Serial.printf("  [FIREBASE ERROR] Gagal mengirim: %s\n", https.errorToString(httpCode).c_str());
    }
    https.end();
  }
}

// --- Modul J: Estimasi Kurva PPM Sensor Gas ---
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
