/**
 * AeroSense IoT - Configuration Settings
 * Konfigurasi Firebase Realtime Database & Ambang Batas Keselamatan
 */

const CONFIG = {
  // Masukkan URL Firebase Realtime Database Anda di sini (atau isi lewat tombol 'Settings' di Web)
  // Contoh: "https://nama-project-kamu-default-rtdb.firebaseio.com"
  FIREBASE_DATABASE_URL: "https://aerosense-safety-default-rtdb.firebaseio.com",

  // Opsional: Database Secret / Auth Token jika Firebase Rules diproteksi
  FIREBASE_AUTH_TOKEN: "",

  // Opsional: Google Gemini API Key jika ingin mengaktifkan respons AI online
  GEMINI_API_KEY: "",

  // Interval pembaruan data (dalam milidetik: 2000 = 2 detik)
  POLL_INTERVAL: 2000,

  // Ambang batas keselamatan (Standar K3 / Jurnal Ilmiah)
  THRESHOLDS: {
    TEMP_MAX: 35.0, // Batas Suhu Panas (°C)
    MQ2_MAX: 300,   // Batas Gas LPG & Asap (PPM)
    MQ7_MAX: 50     // Batas Karbon Monoksida / CO (PPM)
  }
};

// Muat konfigurasi tersimpan dari LocalStorage browser jika ada
(function loadSavedConfig() {
  const savedDbUrl = localStorage.getItem("aerosense_cfg_db_url");
  const savedToken = localStorage.getItem("aerosense_cfg_db_token");
  const savedTempMax = localStorage.getItem("aerosense_cfg_temp_max");
  const savedMq2Max = localStorage.getItem("aerosense_cfg_mq2_max");
  const savedMq7Max = localStorage.getItem("aerosense_cfg_mq7_max");

  if (savedDbUrl !== null) CONFIG.FIREBASE_DATABASE_URL = savedDbUrl;
  if (savedToken !== null) CONFIG.FIREBASE_AUTH_TOKEN = savedToken;
  if (savedTempMax !== null) CONFIG.THRESHOLDS.TEMP_MAX = parseFloat(savedTempMax);
  if (savedMq2Max !== null) CONFIG.THRESHOLDS.MQ2_MAX = parseFloat(savedMq2Max);
  if (savedMq7Max !== null) CONFIG.THRESHOLDS.MQ7_MAX = parseFloat(savedMq7Max);
})();
