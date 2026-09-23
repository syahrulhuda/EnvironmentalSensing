/*
  Uji Coba Hardware & Cloud: ESP32 DevKit V1 (WROOM-32)
  Komponen:
    1. MQ-7 (Carbon Monoxide Sensor) -> Pin D34 (GPIO 34, ADC1) | VCC: 5V
    2. DHT22 (Suhu & Kelembapan)     -> Pin D19 (GPIO 19)       | VCC: 3.3V
  
  Konektivitas:
    - Wi-Fi Station
    - Firebase Realtime Database (HTTPS REST API / Serverless)
  
  Metode: Non-blocking millis()
  Output: Serial Monitor (115200 baud) & Firebase RTDB Console
*/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <DHT.h>

// =============================================================================
// 1. KONFIGURASI WI-FI & FIREBASE REALTIME DATABASE
// =============================================================================
// GANTI DENGAN NAMA & PASSWORD WI-FI / HOTSPOT KAMU
const char* WIFI_SSID = "Poltekom Hotspot";
const char* WIFI_PASS = "poltekomjaya";

// Endpoint Firebase RTDB (Region: asia-southeast1 / Singapura)
const char* FIREBASE_URL = "https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json";

// =============================================================================
// 2. DEFINISI PIN & SENSOR
// =============================================================================
#define MQ7_PIN     34    // GPIO 34 (Input-only, ADC1_CH6 - Aman tanpa konflik Wi-Fi)
#define DHTPIN      19    // GPIO 19 (Data DHT22)
#define DHTTYPE     DHT22 // Tipe sensor DHT22 (AM2302)

DHT dht(DHTPIN, DHTTYPE);

// =============================================================================
// 3. VARIABEL TIMING & NON-BLOCKING MILLIS
// =============================================================================
unsigned long previousMillis = 0;
const unsigned long INTERVAL_BACA = 3000; // Kirim telemetri setiap 3 detik
unsigned long sampleCounter = 0;

// =============================================================================
// 4. FUNGSI ESTIMASI CO (MQ-7)
// =============================================================================
int hitungMq7Ppm(int rawAdc) {
  int constrainedAdc = constrain(rawAdc, 400, 4095);
  return map(constrainedAdc, 400, 4095, 5, 400);
}

// =============================================================================
// 5. FUNGSI PENGIRIMAN DATA KE FIREBASE RTDB (HTTPS REST)
// =============================================================================
void kirimKeFirebase(float temp, float hum, int rawAdc, float volt, int ppm, const char* status) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("  [FIREBASE] Lewati pengiriman: Wi-Fi terputus!");
    return;
  }

  WiFiClientSecure client;
  client.setInsecure(); // Bypass validasi sertifikat SSL agar hemat memori ESP32
  client.setTimeout(4000); // 4 detik timeout

  HTTPClient https;
  if (https.begin(client, FIREBASE_URL)) {
    https.addHeader("Content-Type", "application/json");

    // Bentuk JSON payload secara manual (ringan tanpa butuh library JSON tambahan)
    String jsonPayload = "{";
    jsonPayload += "\"temp\":" + (isnan(temp) ? "null" : String(temp, 1)) + ",";
    jsonPayload += "\"hum\":" + (isnan(hum) ? "null" : String(hum, 1)) + ",";
    jsonPayload += "\"mq7_raw\":" + String(rawAdc) + ",";
    jsonPayload += "\"mq7_volt\":" + String(volt, 2) + ",";
    jsonPayload += "\"mq7_ppm\":" + String(ppm) + ",";
    jsonPayload += "\"status\":\"" + String(status) + "\",";
    jsonPayload += "\"created_at\":{\".sv\":\"timestamp\"}"; // Server timestamp Firebase
    jsonPayload += "}";

    Serial.print("  [FIREBASE POST] ");
    Serial.println(jsonPayload);

    int httpCode = https.POST(jsonPayload);

    if (httpCode > 0) {
      Serial.printf("  [FIREBASE STATUS] HTTP %d | Respon: %s\n", httpCode, https.getString().c_str());
    } else {
      Serial.printf("  [FIREBASE ERROR] Gagal mengirim: %s\n", https.errorToString(httpCode).c_str());
    }

    https.end();
  } else {
    Serial.println("  [FIREBASE ERROR] Gagal menghubungkan ke server Firebase.");
  }
}

// =============================================================================
// 6. SETUP
// =============================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n==================================================");
  Serial.println("   TES ESP32 WROOM + MQ-7 + DHT22 + FIREBASE RTDB ");
  Serial.println("   Laboratorium Mekatronika POLTEKOM              ");
  Serial.println("==================================================");

  // Inisialisasi Sensor
  dht.begin();
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  // Koneksi ke Wi-Fi
  Serial.printf("[WIFI] Menghubungkan ke '%s'", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WIFI] Berhasil terhubung!");
    Serial.print("[WIFI] IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WIFI] Gagal terhubung (Timeout). Program tetap lanjut offline.");
  }

  Serial.println("--------------------------------------------------\n");
}

// =============================================================================
// 7. LOOP UTAMA (NON-BLOCKING)
// =============================================================================
void loop() {
  unsigned long currentMillis = millis();

  // Jalankan siklus setiap INTERVAL_BACA (3000 ms)
  if (currentMillis - previousMillis >= INTERVAL_BACA) {
    previousMillis = currentMillis;
    sampleCounter++;

    // 1. Baca Sensor DHT22
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();

    // 2. Baca Sensor MQ-7
    int rawAdcMq7 = analogRead(MQ7_PIN);
    float voltageMq7 = (rawAdcMq7 / 4095.0) * 3.3;
    int coPpm = hitungMq7Ppm(rawAdcMq7);

    // 3. Tentukan Status K3
    const char* status = "NORMAL";
    if (coPpm > 150) {
      status = "DANGER";
    } else if (coPpm > 50) {
      status = "WARNING";
    }

    // 4. Output ke Serial Monitor
    Serial.printf("[Sample #%lu | Uptime: %lu s]\n", sampleCounter, currentMillis / 1000);
    if (isnan(humidity) || isnan(temperature)) {
      Serial.println("  [DHT22] ERROR: Gagal membaca data.");
    } else {
      Serial.printf("  [DHT22] Suhu: %.1f °C | Kelembapan: %.1f %%\n", temperature, humidity);
    }
    Serial.printf("  [MQ-7]  Raw ADC: %d | Tegangan: %.2f V | Est. CO: %d PPM | Status: %s\n", 
                  rawAdcMq7, voltageMq7, coPpm, status);

    // 5. Kirim Telemetri ke Firebase RTDB
    kirimKeFirebase(temperature, humidity, rawAdcMq7, voltageMq7, coPpm, status);

    Serial.println("--------------------------------------------------");
  }
}
