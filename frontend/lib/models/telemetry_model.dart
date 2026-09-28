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
  });

  /// Factory untuk memetakan payload dari /telemetry/buffer.json
  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    final rawTemp = json['temp'] ?? json['temperature'] ?? 25.0;
    final rawHum = json['hum'] ?? json['humidity'] ?? 55.0;
    final rawCo = json['mq7_ppm'] ?? 0;
    final rawSmoke = json['mq2_ppm'] ?? json['mq2'] ?? 100;
    final rawVolt = json['mq7_volt'] ?? 0.0;
    final rawAdc = json['mq7_raw'] ?? 0;
    final rawNode = json['node_id'] ?? 'NODE-MRS01';
    final rawStatus = json['status'] ?? 'NORMAL';
    
    DateTime time;
    if (json['created_at'] != null) {
      final ts = json['created_at'];
      time = ts is int ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now();
    } else {
      time = DateTime.now();
    }

    return TelemetryModel(
      temperature: (rawTemp as num).toDouble(),
      humidity: (rawHum as num).toDouble(),
      mq7CoPpm: (rawCo as num).toInt(),
      mq2SmokePpm: (rawSmoke as num).toInt(),
      mq7Volt: (rawVolt as num).toDouble(),
      mq7Raw: (rawAdc as num).toInt(),
      nodeId: rawNode.toString(),
      status: rawStatus.toString(),
      timestamp: time,
    );
  }

  /// Initial placeholder data saat aplikasi pertama kali boot
  factory TelemetryModel.initial() {
    return TelemetryModel(
      temperature: 25.9,
      humidity: 57.8,
      mq7CoPpm: 5,
      mq2SmokePpm: 110,
      mq7Volt: 0.3,
      mq7Raw: 368,
      nodeId: 'NODE-MRS01',
      status: 'NORMAL',
      timestamp: DateTime.now(),
    );
  }
}
