/*
  Environmental Sensing System (ESS) - Hardware Test Bench ESP32-C3
  Mode: Standalone / Offline (Tanpa Wi-Fi)
  Target: ESP32-C3 SuperMini + Breadboard Prototype

  Pinout:
    - OLED SSD1306 (0.96" I2C) : SDA -> GPIO 8, SCL -> GPIO 9 (0x3C)
    - DHT22 (Suhu & Hum)       : DATA -> GPIO 10 (Pull-up 10k)
    - MQ-7 (Karbon Monoksida)  : AO   -> GPIO 1 (ADC1_CH1)
    - MQ-2 (Asap & Gas)        : AO   -> GPIO 0 (ADC1_CH0)
    - LED RGB (Common Cathode) : R -> GPIO 4, G -> GPIO 3, B -> GPIO 2
    - Fan PWM (Transistor NPN) : PWM -> GPIO 5 (R5 1k ke Basis SS8050)
*/

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>

// --- PIN DEFINITIONS ---
#define PIN_OLED_SDA  8
#define PIN_OLED_SCL  9
#define PIN_DHT       10
#define PIN_MQ7       1
#define PIN_MQ2       0
#define PIN_LED_R     4
#define PIN_LED_G     3
#define PIN_LED_B     2
#define PIN_FAN_PWM   5

#define DHT_TYPE      DHT22
#define OLED_ADDR     0x3C
#define SCREEN_W      128
#define SCREEN_H      64

// --- K3 THRESHOLDS (PPM) ---
#define MQ7_WARN_PPM   50
#define MQ7_DANGER_PPM 150
#define MQ2_WARN_PPM   150
#define MQ2_DANGER_PPM 400

// --- KALIBRASI BASELINE UDARA BERSIH (CLEAN AIR ADC) & OFFSET SUHU ---
#define MQ7_BASELINE_ADC 1550  // Nilai idle ADC MQ-7 di udara bersih (~1.25V)
#define MQ2_BASELINE_ADC 460   // Nilai idle ADC MQ-2 di udara bersih (~0.37V)
#define TEMP_OFFSET      0.0   // Offset suhu (°C). Jika terpengaruh panas heater MQ, ubah misal: -3.0

// --- KIPAS DC PWM DEFINITIONS ---
#define FAN_PWM_STOP   0    // 0%   (0.00V) - Mati
#define FAN_PWM_LOW    89   // 35%  (~1.75V) - Mode Senyap / Tenang (K3 Normal)
#define FAN_PWM_MED    165  // 65%  (~3.25V) - Mode Sedang (K3 Warning)
#define FAN_PWM_HIGH   255  // 100% (~4.95V) - Mode Purge Maksimal (K3 Danger)

// --- OBJECTS & TIMERS ---
Adafruit_SSD1306 display(SCREEN_W, SCREEN_H, &Wire, -1);
DHT dht(PIN_DHT, DHT_TYPE);

bool oledOk = false;
unsigned long prevRead = 0;
unsigned long prevStrobe = 0;
const unsigned long INTERVAL_READ = 2500; // Baca sensor tiap 2.5 detik
bool strobeState = false;
unsigned long sampleNum = 0;

// --- PROTOTYPES ---
void setRgb(bool r, bool g, bool b);
void setFanPwm(int duty);
int getMq7Ppm(int adc);
int getMq2Ppm(int adc);
void updateOled(float t, float h, bool dhtOk, int co, int gas, const char* status);

void setup() {
  Serial.begin(115200);

  // 1. Inisialisasi Pin Output LED RGB & Driver Kipas PWM
  pinMode(PIN_LED_R, OUTPUT);
  pinMode(PIN_LED_G, OUTPUT);
  pinMode(PIN_LED_B, OUTPUT);
  pinMode(PIN_FAN_PWM, OUTPUT);

  setRgb(0, 0, 0);
  setFanPwm(FAN_PWM_STOP);

  delay(500);
  Serial.println("\n=== [ESS] ESP32-C3 HARDWARE TEST BENCH ===");
  Serial.println("[TEST] Uji Mandiri LED RGB & Driver PWM Kipas SS8050...");
  
  // Tahap 0: Semua Mati
  Serial.println("  -> [Tahap 0] Semua MATI | PWM: 0% (Target Multimeter: 0.00 V)...");
  setRgb(0, 0, 0);
  setFanPwm(FAN_PWM_STOP);
  delay(1500);

  // Tahap 1: HIJAU + PWM 35% (~1.75V)
  Serial.println("  -> [Tahap 1] LED HIJAU (GPIO 3) | Kipas TENANG | PWM: 35% (Target Multimeter: ~1.75 V)...");
  setRgb(0, 1, 0);
  setFanPwm(FAN_PWM_LOW);
  delay(2500);

  // Tahap 2: KUNING + PWM 65% (~3.25V)
  Serial.println("  -> [Tahap 2] LED KUNING (GPIO 4+3) | Kipas SEDANG | PWM: 65% (Target Multimeter: ~3.25 V)...");
  setRgb(1, 1, 0);
  setFanPwm(FAN_PWM_MED);
  delay(2500);

  // Tahap 3: MERAH + PWM 100% (~4.95V)
  Serial.println("  -> [Tahap 3] LED MERAH (GPIO 4) | Kipas MAKSIMAL | PWM: 100% (Target Multimeter: ~4.95 V)...");
  setRgb(1, 0, 0);
  setFanPwm(FAN_PWM_HIGH);
  delay(2500);

  // Tahap 4: BIRU (Standby)
  Serial.println("  -> [Tahap 4] LED BIRU (GPIO 2) | Standby...");
  setRgb(0, 0, 1);
  setFanPwm(FAN_PWM_STOP);
  delay(1500);

  setRgb(0, 0, 0);
  Serial.println("[TEST] Uji Mandiri Selesai. Masuk ke Loop Telemetri Sensor.\n");
  Serial.flush();

  // 2. Init I2C & OLED (dengan Proteksi Timeout Anti-Freeze)
  Wire.begin(PIN_OLED_SDA, PIN_OLED_SCL);
  Wire.setTimeOut(50); // Timeout 50ms agar tidak hang jika I2C bermasalah

  Wire.beginTransmission(OLED_ADDR);
  byte i2cErr = Wire.endTransmission();

  if (i2cErr == 0) {
    if (display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR, false, false)) {
      oledOk = true;
      display.clearDisplay();
      display.setTextColor(SSD1306_WHITE);
      display.setTextSize(1);
      display.setCursor(15, 20);
      display.print("POLTEKOM ESS");
      display.setCursor(15, 35);
      display.print("TEST BENCH C3");
      display.display();
      Serial.println("[OK] OLED SSD1306 128x64 terdeteksi (0x3C)");
    } else {
      Serial.println("[ERR] Init Adafruit OLED gagal");
    }
  } else {
    Serial.printf("[ERR] OLED tidak merespons I2C (Kode Error: %d)\n", i2cErr);
    Serial.println("      -> Cek kabel SDA(8), SCL(9), VCC(5V), GND");
  }
  Serial.flush();

  // 3. Init DHT22 & ADC
  dht.begin();
  analogReadResolution(12);
  Serial.println("[OK] ADC 12-bit & DHT22 diinisialisasi");
  Serial.println("==========================================\n");
  Serial.flush();

  delay(500);
}

void loop() {
  unsigned long now = millis();

  // Evaluasi dan baca sensor secara periodik
  static const char* curStatus = "NORMAL";
  static int currentPwm = FAN_PWM_LOW;
  static const char* fanStateStr = "35%(~1.75V)";

  if (now - prevRead >= INTERVAL_READ) {
    prevRead = now;
    sampleNum++;

    // 1. Baca DHT22 (dengan kompensasi offset suhu mikro-termal)
    float hum = dht.readHumidity();
    float rawTemp = dht.readTemperature();
    float temp = rawTemp + TEMP_OFFSET;
    bool dhtOk = !isnan(hum) && !isnan(rawTemp);

    // 2. Baca MQ-7 (CO)
    int adcMq7 = analogRead(PIN_MQ7);
    float vMq7 = (adcMq7 / 4095.0) * 3.3;
    int ppmMq7 = getMq7Ppm(adcMq7);

    // 3. Baca MQ-2 (Asap/Gas)
    int adcMq2 = analogRead(PIN_MQ2);
    float vMq2 = (adcMq2 / 4095.0) * 3.3;
    int ppmMq2 = getMq2Ppm(adcMq2);

    // 4. Evaluasi Status K3 & Set Kecepatan Kipas PWM
    if (ppmMq7 >= MQ7_DANGER_PPM || ppmMq2 >= MQ2_DANGER_PPM) {
      curStatus = "DANGER";
      currentPwm = FAN_PWM_HIGH;
      fanStateStr = "100%(~4.95V)";
    } else if (ppmMq7 >= MQ7_WARN_PPM || ppmMq2 >= MQ2_WARN_PPM) {
      curStatus = "WARNING";
      currentPwm = FAN_PWM_MED;
      fanStateStr = "65%(~3.25V)";
    } else {
      curStatus = "NORMAL";
      currentPwm = FAN_PWM_LOW;
      fanStateStr = "35%(~1.75V)";
    }

    setFanPwm(currentPwm);

    // 5. Output Serial Monitor (Atomic Single Line Buffer - Anti Truncation)
    char logBuf[180];
    char dhtStr[32];
    if (dhtOk) {
      snprintf(dhtStr, sizeof(dhtStr), "T:%.1fC H:%.1f%%", temp, hum);
    } else {
      snprintf(dhtStr, sizeof(dhtStr), "T:[ERR] H:[ERR]");
    }

    const char* ledStateStr = (strcmp(curStatus, "DANGER") == 0) ? "MERAH_KEDIP" :
                              ((strcmp(curStatus, "WARNING") == 0) ? "KUNING_ON" : "HIJAU_ON");

    snprintf(logBuf, sizeof(logBuf),
             "[#%03lu] %s | MQ7:%3d ppm (ADC:%4d, %.2fV) | MQ2:%3d ppm (ADC:%4d, %.2fV) | K3:%s | LED:%s | FAN:%s",
             sampleNum, dhtStr, ppmMq7, adcMq7, vMq7, ppmMq2, adcMq2, vMq2, curStatus, ledStateStr, fanStateStr);
    Serial.println(logBuf);
    Serial.flush();

    // 6. Update Layar OLED jika tersedia
    if (oledOk) {
      updateOled(temp, hum, dhtOk, ppmMq7, ppmMq2, curStatus);
    }
  }

  // Indikator Visual LED RGB (Real-time Non-blocking)
  if (strcmp(curStatus, "DANGER") == 0) {
    if (now - prevStrobe >= 150) {
      prevStrobe = now;
      strobeState = !strobeState;
      setRgb(strobeState, 0, 0); // Merah Kedip Cepat
    }
  } else if (strcmp(curStatus, "WARNING") == 0) {
    setRgb(1, 1, 0); // Kuning Solid
  } else {
    setRgb(0, 1, 0); // Hijau Solid
  }
}

// Helper: Kendali LED RGB Common Cathode
void setRgb(bool r, bool g, bool b) {
  digitalWrite(PIN_LED_R, r ? HIGH : LOW);
  digitalWrite(PIN_LED_G, g ? HIGH : LOW);
  digitalWrite(PIN_LED_B, b ? HIGH : LOW);
}

// Helper: Kendali Kecepatan Kipas PWM (SS8050 Low-Side Switch)
void setFanPwm(int duty) {
  duty = constrain(duty, 0, 255);
  analogWrite(PIN_FAN_PWM, duty);
}

// Estimasi PPM MQ-7 (CO) dengan Kalibrasi Baseline Udara Bersih
int getMq7Ppm(int adc) {
  int constrainedAdc = constrain(adc, MQ7_BASELINE_ADC, 4095);
  return map(constrainedAdc, MQ7_BASELINE_ADC, 4095, 5, 400);
}

// Estimasi PPM MQ-2 (Gas/Asap) dengan Kalibrasi Baseline Udara Bersih
int getMq2Ppm(int adc) {
  int constrainedAdc = constrain(adc, MQ2_BASELINE_ADC, 4095);
  return map(constrainedAdc, MQ2_BASELINE_ADC, 4095, 5, 1000);
}

// Render OLED Compact
void updateOled(float t, float h, bool dhtOk, int co, int gas, const char* status) {
  display.clearDisplay();

  // Header
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("POLTEKOM ESS [OFFLINE]");
  display.drawFastHLine(0, 10, 128, SSD1306_WHITE);

  // Baris Suhu & Hum
  display.setCursor(0, 14);
  if (dhtOk) {
    display.printf("Suhu: %.1f C  RH: %.0f%%", t, h);
  } else {
    display.print("DHT22: ERROR SENSOR");
  }

  // Baris Gas & Status Kipas
  display.setCursor(0, 26);
  display.printf("CO  : %3d ppm", co);
  display.setCursor(76, 26);
  display.printf("Fan:%s", (strcmp(status, "DANGER") == 0) ? "100%" :
                           ((strcmp(status, "WARNING") == 0) ? "65%" : "35%"));

  display.setCursor(0, 37);
  display.printf("Asap: %3d ppm", gas);

  // Banner Status
  if (strcmp(status, "DANGER") == 0) {
    display.fillRect(0, 50, 128, 14, SSD1306_WHITE);
    display.setTextColor(SSD1306_BLACK, SSD1306_WHITE);
    display.setCursor(18, 53);
    display.print("! BAHAYA K3 !");
  } else if (strcmp(status, "WARNING") == 0) {
    display.drawRect(0, 50, 128, 14, SSD1306_WHITE);
    display.setCursor(20, 53);
    display.print("* WASPADA K3 *");
  } else {
    display.drawRect(0, 50, 128, 14, SSD1306_WHITE);
    display.setCursor(20, 53);
    display.print("[ STATUS AMAN ]");
  }

  display.display();
}
