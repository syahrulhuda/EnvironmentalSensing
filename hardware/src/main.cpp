/*
  Environmental Sensing IoT Node - ESP32-C3 Super Mini
  Arsitektur Modular & Non-blocking (PlatformIO / Wokwi / Fritzing)
  
  Pinout (ESP32-C3 Super Mini):
    - DHT22 Data: GPIO 10
    - MQ-2 Analog Out (ADC1_CH0): GPIO 0
    - MQ-7 Analog Out (ADC1_CH1): GPIO 1
    - LCD 16x2 I2C SDA: GPIO 8
    - LCD 16x2 I2C SCL: GPIO 9
*/

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <ArduinoJson.h>

// =============================================================================
// 1. KONFIGURASI PIN & HARDWARE
// =============================================================================
#define DHTPIN 10
#define DHTTYPE DHT22
#define MQ2_PIN 0      // GPIO 0 (ADC1_CH0)
#define MQ7_PIN 1      // GPIO 1 (ADC1_CH1)
#define I2C_SDA 8      // GPIO 8 (Hardware SDA)
#define I2C_SCL 9      // GPIO 9 (Hardware SCL)

// LED RGB (Common Cathode)
#define LED_RED   4    // GPIO 4 (Anoda Merah)
#define LED_GREEN 3    // GPIO 3 (Anoda Hijau)
#define LED_BLUE  2    // GPIO 2 (Anoda Biru)

// =============================================================================
// 2. AMBANG BATAS GAS (PPM)
// =============================================================================
// MQ-2 (Asap & Gas Mudah Terbakar)
#define MQ2_WARN_THRESHOLD  300
#define MQ2_ALARM_THRESHOLD 600

// MQ-7 (Karbon Monoksida / CO)
#define MQ7_WARN_THRESHOLD  50
#define MQ7_ALARM_THRESHOLD 150

// =============================================================================
// 3. KONFIGURASI JARINGAN & SERVER
// =============================================================================
// Simulasi Wokwi pakai "Wokwi-GUEST". Jika di ESP32 asli ganti dengan Wi-Fi kamu.
const char* WIFI_SSID = "Wokwi-GUEST";
const char* WIFI_PASS = "";

// Endpoint REST API (Firebase / Flask)
// Contoh Firebase: "https://<PROJECT_ID>-default-rtdb.firebaseio.com/telemetry.json"
String serverUrl = "http://127.0.0.1:5000/sensor-data";

// =============================================================================
// 4. STRUKTUR DATA & OBJEK GLOBAL
// =============================================================================
struct SensorData {
  float temperature = 0.0;
  float humidity = 0.0;
  bool dhtValid = false;

  int rawMq2 = 0;
  int rawMq7 = 0;
  int mq2Ppm = 0;
  int mq7Ppm = 0;

  float hazardMq2 = 0.0;
  float hazardMq7 = 0.0;

  const char* airStatus = "NORMAL"; // "NORMAL", "WARNING", "DANGER"
} telemetry;

DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Timing Intervals (Non-blocking Millis)
const unsigned long LCD_INTERVAL = 3000;    // Ganti halaman LCD tiap 3 detik
const unsigned long POST_INTERVAL = 10000;  // Kirim data ke cloud tiap 10 detik

unsigned long lastLcdUpdate = 0;
unsigned long lastCloudPost = 0;
int lcdPage = 0;                            // 0 = Main Screen, 1 = Detail Screen

// =============================================================================
// 5. PROTOTIPE FUNGSI
// =============================================================================
void initHardware();
void connectWiFi();
void readDhtSensor();
void readGasSensors();
void evaluateAirQuality();
void updateLcdDisplay();
void printLcdLine(uint8_t row, const char* str);
void updateRgbIndicator();
void setRgbColor(bool red, bool green, bool blue);
void sendTelemetryRest();
int calculateMq2Ppm(int rawAdc);
int calculateMq7Ppm(int rawAdc);

// =============================================================================
// 6. SETUP & LOOP UTAMA (RINGKAS & MODULAR)
// =============================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n========================================");
  Serial.println("Environmental Sensing Node");
  Serial.println("========================================");

  initHardware();
  connectWiFi();

  delay(1500);
  lcd.clear();
}

void loop() {
  unsigned long currentMillis = millis();

  // 1. Selalu perbarui pembacaan sensor fisik & evaluasi status kualitas udara
  readDhtSensor();
  readGasSensors();
  evaluateAirQuality();

  // 2. Indikator Visual K3 (LED RGB)
  updateRgbIndicator();

  // 3. Tugas Rutin A: Pembaruan Tampilan LCD (tiap 3 detik)
  if (currentMillis - lastLcdUpdate >= LCD_INTERVAL) {
    lastLcdUpdate = currentMillis;
    updateLcdDisplay();
  }

  // 4. Tugas Rutin B: Pengiriman Telemetri REST API (tiap 10 detik)
  if (currentMillis - lastCloudPost >= POST_INTERVAL) {
    lastCloudPost = currentMillis;
    sendTelemetryRest();
  }
}

// =============================================================================
// 7. IMPLEMENTASI MODUL-MODUL FUNGSI
// =============================================================================

// --- Modul A: Inisialisasi Perangkat Keras ---
void initHardware() {
  // Bus I2C ESP32-C3 (SDA=8, SCL=9)
  Wire.begin(I2C_SDA, I2C_SCL);

  // Pin Output LED RGB (Common Cathode)
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  setRgbColor(0, 0, 0); // Matikan saat awal

  // LCD 16x2
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("ESP32-C3 Node");
  lcd.setCursor(0, 1);
  lcd.print("Init Hardware...");

  // Sensor DHT22
  dht.begin();

  // Resolusi ADC 12-bit (0 - 4095)
  analogReadResolution(12);

  Serial.println("[INIT] Perangkat keras berhasil diinisialisasi.");
}

// --- Modul B: Koneksi Jaringan Wi-Fi ---
void connectWiFi() {
  Serial.print("[NET] Menghubungkan ke Wi-Fi: ");
  Serial.println(WIFI_SSID);

  lcd.setCursor(0, 1);
  lcd.print("Connecting Wi-Fi");

  WiFi.begin(WIFI_SSID, WIFI_PASS);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[NET] Wi-Fi Terhubung!");
    Serial.print("[NET] IP Address: ");
    Serial.println(WiFi.localIP());

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Wi-Fi Connected!");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
  } else {
    Serial.println("\n[WARN] Timeout Wi-Fi. Masuk ke Mode Offline.");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Wi-Fi Offline");
    lcd.setCursor(0, 1);
    lcd.print("Running Local");
  }
}

// --- Modul C: Pembacaan Sensor DHT22 (Suhu & Kelembaban) ---
void readDhtSensor() {
  telemetry.humidity = dht.readHumidity();
  telemetry.temperature = dht.readTemperature();
  telemetry.dhtValid = !isnan(telemetry.humidity) && !isnan(telemetry.temperature);
}

// --- Modul D: Pembacaan Sensor Gas (MQ-2 & MQ-7) & Rasio Bahaya ---
void readGasSensors() {
  telemetry.rawMq2 = analogRead(MQ2_PIN);
  telemetry.rawMq7 = analogRead(MQ7_PIN);

  telemetry.mq2Ppm = calculateMq2Ppm(telemetry.rawMq2);
  telemetry.mq7Ppm = calculateMq7Ppm(telemetry.rawMq7);

  // Rasio Tingkat Bahaya Relatif terhadap Ambang Waspada
  telemetry.hazardMq2 = (float)telemetry.mq2Ppm / (float)MQ2_WARN_THRESHOLD;
  telemetry.hazardMq7 = (float)telemetry.mq7Ppm / (float)MQ7_WARN_THRESHOLD;
}

// --- Modul E: Evaluasi Tingkat Kualitas Udara ---
void evaluateAirQuality() {
  if (telemetry.mq2Ppm >= MQ2_ALARM_THRESHOLD || telemetry.mq7Ppm >= MQ7_ALARM_THRESHOLD) {
    telemetry.airStatus = "DANGER";
  } else if (telemetry.mq2Ppm >= MQ2_WARN_THRESHOLD || telemetry.mq7Ppm >= MQ7_WARN_THRESHOLD) {
    telemetry.airStatus = "WARNING";
  } else {
    telemetry.airStatus = "NORMAL";
  }
}

// --- Modul F: Logika Tampilan LCD 16x2 ---
void updateLcdDisplay() {
  char line0[17];
  char line1[17];

  // Format ringkasan Suhu & Kelembaban
  char thBuf[17];
  if (telemetry.dhtValid) {
    snprintf(thBuf, sizeof(thBuf), "T:%.1f%cC M:%.1f%%", telemetry.temperature, (char)223, telemetry.humidity);
  } else {
    snprintf(thBuf, sizeof(thBuf), "T:ERR   M:ERR   ");
  }

  // Format gabungan kedua gas (tepat 16 karakter tanpa terpotong: "G:350p  C: 55ppm")
  char gasCombinedBuf[17];
  snprintf(gasCombinedBuf, sizeof(gasCombinedBuf), "G:%3dp  C:%3dppm", telemetry.mq2Ppm, telemetry.mq7Ppm);

  // Percabangan tampilan berdasarkan kondisi status
  if (strcmp(telemetry.airStatus, "DANGER") == 0) {
    // === STATUS DANGER ===
    snprintf(line0, sizeof(line0), "! DANGER ALERT !");
    if (lcdPage == 0) {
      snprintf(line1, sizeof(line1), "%s", gasCombinedBuf);
      lcdPage = 1;
    } else {
      snprintf(line1, sizeof(line1), "%s", thBuf);
      lcdPage = 0;
    }
  } else if (strcmp(telemetry.airStatus, "WARNING") == 0) {
    // === STATUS WARNING ===
    snprintf(line0, sizeof(line0), "*** WARNING! ***");
    if (lcdPage == 0) {
      snprintf(line1, sizeof(line1), "%s", gasCombinedBuf);
      lcdPage = 1;
    } else {
      snprintf(line1, sizeof(line1), "%s", thBuf);
      lcdPage = 0;
    }
  } else {
    // === STATUS NORMAL ===
    if (lcdPage == 0) {
      // Main Screen: Suhu/Kelembaban + Gas dengan rasio bahaya lebih tinggi
      snprintf(line0, sizeof(line0), "%s", thBuf);
      if (telemetry.hazardMq7 > telemetry.hazardMq2) {
        snprintf(line1, sizeof(line1), "CO  : %4d PPM", telemetry.mq7Ppm);
      } else {
        snprintf(line1, sizeof(line1), "GAS : %4d PPM", telemetry.mq2Ppm);
      }
      lcdPage = 1;
    } else {
      // Detail Screen: Rincian kedua gas
      snprintf(line0, sizeof(line0), "GAS : %4d PPM", telemetry.mq2Ppm);
      snprintf(line1, sizeof(line1), "CO  : %4d PPM", telemetry.mq7Ppm);
      lcdPage = 0;
    }
  }

  // Tulis ke layar (dengan auto-padding 16 karakter agar anti-kedip)
  printLcdLine(0, line0);
  printLcdLine(1, line1);

  // Log ke Serial Monitor
  Serial.printf("[SENSOR] %s | %s | H_MQ2: %.2f | H_MQ7: %.2f | Status: %s\n",
                thBuf, gasCombinedBuf, telemetry.hazardMq2, telemetry.hazardMq7, telemetry.airStatus);
}

// Helper untuk mencetak 1 baris LCD dengan padding tepat 16 karakter
void printLcdLine(uint8_t row, const char* str) {
  lcd.setCursor(0, row);
  char lineBuf[17];
  snprintf(lineBuf, sizeof(lineBuf), "%-16.16s", str);
  lcd.print(lineBuf);
}

// --- Modul G: Pengiriman Data Telemetri via REST API ---
void sendTelemetryRest() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[NET] Wi-Fi terputus, mencoba menyambung ulang...");
    WiFi.reconnect();
    return;
  }

  if (!telemetry.dhtValid) {
    Serial.println("[WARN] Data DHT tidak valid, pengiriman dibatalkan.");
    return;
  }

  HTTPClient http;
  http.begin(serverUrl);
  http.addHeader("Content-Type", "application/json");

  // Format payload JSON telemetri
  StaticJsonDocument<256> doc;
  doc["temperature"] = round(telemetry.temperature * 10.0) / 10.0;
  doc["humidity"] = round(telemetry.humidity * 10.0) / 10.0;
  doc["mq2_ppm"] = telemetry.mq2Ppm;
  doc["mq7_ppm"] = telemetry.mq7Ppm;
  doc["hazard_mq2"] = round(telemetry.hazardMq2 * 100.0) / 100.0;
  doc["hazard_mq7"] = round(telemetry.hazardMq7 * 100.0) / 100.0;
  doc["status"] = telemetry.airStatus;

  String jsonPayload;
  serializeJson(doc, jsonPayload);

  Serial.print("[HTTP POST] Mengirim payload: ");
  Serial.println(jsonPayload);

  int httpCode = http.POST(jsonPayload);

  if (httpCode > 0) {
    String response = http.getString();
    Serial.printf("[HTTP STATUS] %d | Respon: %s\n", httpCode, response.c_str());
  } else {
    Serial.printf("[HTTP ERROR] Gagal mengirim: %s\n", http.errorToString(httpCode).c_str());
  }

  http.end();
}

// --- Modul H: Estimasi Kurva PPM Sensor Gas ---
// MQ-2: Combustible Gas & Asap (Baseline udara bersih ~800 ADC = 10 PPM)
int calculateMq2Ppm(int rawAdc) {
  int constrainedAdc = constrain(rawAdc, 800, 4095);
  return map(constrainedAdc, 800, 4095, 10, 1000);
}

// MQ-7: Karbon Monoksida (Baseline udara bersih ~800 ADC = 5 PPM, ambang waspada 50 PPM)
int calculateMq7Ppm(int rawAdc) {
  int constrainedAdc = constrain(rawAdc, 800, 4095);
  return map(constrainedAdc, 800, 4095, 5, 400);
}

// --- Modul I: Indikator Visual K3 (LED RGB Common Cathode) ---
void setRgbColor(bool red, bool green, bool blue) {
  digitalWrite(LED_RED, red ? HIGH : LOW);
  digitalWrite(LED_GREEN, green ? HIGH : LOW);
  digitalWrite(LED_BLUE, blue ? HIGH : LOW);
}

void updateRgbIndicator() {
  if (strcmp(telemetry.airStatus, "DANGER") == 0) {
    // STATUS DANGER: Merah Berkedip Cepat (Strobe 150ms)
    static unsigned long lastStrobe = 0;
    static bool strobeState = false;
    if (millis() - lastStrobe >= 150) {
      lastStrobe = millis();
      strobeState = !strobeState;
      setRgbColor(strobeState, 0, 0); // Merah berkedip darurat
    }
  } else if (strcmp(telemetry.airStatus, "WARNING") == 0) {
    // STATUS WARNING: Kuning Solid (Merah + Hijau)
    setRgbColor(1, 1, 0);
  } else {
    // STATUS NORMAL: Hijau Solid
    setRgbColor(0, 1, 0);
  }
}

