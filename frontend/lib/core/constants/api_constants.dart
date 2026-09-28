/// Konstanta Endpoint API & Ambang Batas Keselamatan ESS
/// Mengikuti Pilar 1 (K3 Mindset) dan Pilar 5 (Zero Secrets) RULEBOOK.md
class ApiConstants {
  // 1. Layer 2 Transport: Hot Buffer Firebase RTDB
  static const String defaultFirebaseRtdbUrl =
      'https://environmental-sensing-f6e1c-default-rtdb.asia-southeast1.firebasedatabase.app/telemetry/buffer.json';

  // 2. Layer 4 Intelligence: FastAPI Gateway & ESI Agent (Raspberry Pi 3B Ngrok Tunnel)
  static const String defaultBackendApiUrl = 'https://entrap-glamour-spectrum.ngrok-free.dev';

  // 3. Node ID Bengkel Mekatronika
  static const String defaultNodeId = 'NODE-MRS01';

  // 4. Polling Interval
  static const Duration pollingInterval = Duration(seconds: 2);

  // 5. Ambang Batas Keselamatan K3 ESS (Pilar 1 RULEBOOK)
  static const double tempMaxThreshold = 35.0; // °C
  static const int mq2MaxThreshold = 300;      // PPM (Asap/Las)
  static const int mq7MaxThreshold = 50;       // PPM (Karbon Monoksida / CO)
}
