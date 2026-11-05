/// Model Data Telemetri ESS (Hot Buffer Firebase & Realtime Stream)
class TelemetryModel {
  final double temperature;
  final double humidity;
  final int mq7CoPpm;
  final int mq2SmokePpm;
  final double mq7Volt;
  final int mq7Raw;
  final String nodeId;
  final String status;
  final DateTime timestamp;
  final bool isOnline;

  const TelemetryModel({
    required this.temperature,
    required this.humidity,
    required this.mq7CoPpm,
    required this.mq2SmokePpm,
    required this.mq7Volt,
    required this.mq7Raw,
    required this.nodeId,
    required this.status,
    required this.timestamp,
    this.isOnline = true,
  });

  /// Factory untuk memetakan payload dari FastAPI Gateway (/api/telemetry/latest) maupun RTDB buffer
  factory TelemetryModel.fromJson(Map<String, dynamic> json, {bool isOnline = true}) {
    final rawTemp = json['temp'] ?? json['temperature_celsius'] ?? json['temperature'] ?? 0.0;
    final rawHum = json['hum'] ?? json['humidity_percent'] ?? json['humidity'] ?? 0.0;
    final rawCo = json['mq7_ppm'] ?? json['mq7_co_ppm'] ?? 0;
    final rawSmoke = json['mq2_ppm'] ?? json['mq2_smoke_ppm'] ?? json['mq2'] ?? 0;
    final rawVolt = json['mq7_volt'] ?? json['mq7_voltage'] ?? 0.0;
    final rawAdc = json['mq7_raw'] ?? json['mq7_raw_adc'] ?? 0;
    final rawNode = json['node_id'] ?? json['device_id'] ?? 'NODE-MRS01';
    final rawStatus = json['status_lingkungan'] ?? json['status'] ?? (isOnline ? 'NORMAL' : 'OFFLINE');
    
    DateTime time;
    if (json['created_at'] != null) {
      final ts = json['created_at'];
      time = ts is int
          ? DateTime.fromMillisecondsSinceEpoch(ts > 1000000000000 ? ts : ts * 1000)
          : DateTime.now();
    } else {
      time = DateTime.now();
    }

    final double tempVal = (rawTemp is num) ? rawTemp.toDouble() : 0.0;
    final double humVal = (rawHum is num) ? rawHum.toDouble() : 0.0;
    final int coVal = (rawCo is num) ? rawCo.toInt() : 0;
    final int smokeVal = (rawSmoke is num) ? rawSmoke.toInt() : 0;
    final double voltVal = (rawVolt is num) ? rawVolt.toDouble() : 0.0;
    final int adcVal = (rawAdc is num) ? rawAdc.toInt() : 0;

    return TelemetryModel(
      temperature: tempVal,
      humidity: humVal,
      mq7CoPpm: coVal,
      mq2SmokePpm: smokeVal,
      mq7Volt: voltVal,
      mq7Raw: adcVal,
      nodeId: rawNode.toString(),
      status: rawStatus.toString(),
      timestamp: time,
      isOnline: isOnline,
    );
  }

  /// Initial state saat aplikasi pertama kali dibuka sebelum data telemetri tiba (Zero Mock Data)
  factory TelemetryModel.initial() {
    return TelemetryModel(
      temperature: 0.0,
      humidity: 0.0,
      mq7CoPpm: 0,
      mq2SmokePpm: 0,
      mq7Volt: 0.0,
      mq7Raw: 0,
      nodeId: 'NODE-MRS01',
      status: 'OFFLINE',
      timestamp: DateTime.now(),
      isOnline: false,
    );
  }

  TelemetryModel copyWith({
    double? temperature,
    double? humidity,
    int? mq7CoPpm,
    int? mq2SmokePpm,
    double? mq7Volt,
    int? mq7Raw,
    String? nodeId,
    String? status,
    DateTime? timestamp,
    bool? isOnline,
  }) {
    return TelemetryModel(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      mq7CoPpm: mq7CoPpm ?? this.mq7CoPpm,
      mq2SmokePpm: mq2SmokePpm ?? this.mq2SmokePpm,
      mq7Volt: mq7Volt ?? this.mq7Volt,
      mq7Raw: mq7Raw ?? this.mq7Raw,
      nodeId: nodeId ?? this.nodeId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
