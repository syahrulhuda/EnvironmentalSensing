import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/telemetry_model.dart';

/// Service untuk mengambil data telemetri ESS via FastAPI Gateway (Single Gateway)
/// dengan secondary fallback ke Firebase RTDB buffer dan deteksi status OFFLINE (Pilar 1 & 5)
class TelemetryService {
  String backendUrl = ApiConstants.defaultBackendApiUrl;
  String firebaseUrl = ApiConstants.defaultFirebaseRtdbUrl;
  String nodeId = ApiConstants.defaultNodeId;

  final _controller = StreamController<TelemetryModel>.broadcast();
  Timer? _pollingTimer;

  Stream<TelemetryModel> get telemetryStream => _controller.stream;

  void startPolling({Duration interval = ApiConstants.pollingInterval}) {
    _pollingTimer?.cancel();
    fetchLatest();
    _pollingTimer = Timer.periodic(interval, (_) => fetchLatest());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<TelemetryModel?> fetchLatest() async {
    // 1. Jalur Utama: FastAPI Single Gateway (TD-F02)
    try {
      final cleanBase = backendUrl.replaceAll(RegExp(r'/+$'), '');
      final endpoint = Uri.parse('$cleanBase/api/telemetry/latest?device_id=$nodeId');
      final res = await http.get(
        endpoint,
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded != null && decoded is Map<String, dynamic>) {
          if (decoded['status'] == 'success' || decoded['temperature_celsius'] != null || decoded['temp'] != null) {
            final model = TelemetryModel.fromJson(decoded, isOnline: true);
            _controller.add(model);
            return model;
          }
        }
      }
    } catch (_) {
      // Backend Gateway unreachable / timeout -> fallback ke Firebase RTDB
    }

    // 2. Jalur Cadangan (Secondary Fallback): Direct Hot Buffer Firebase RTDB
    try {
      final res = await http.get(Uri.parse(firebaseUrl)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded != null && decoded is Map) {
          final entries = decoded.values.toList();
          if (entries.isNotEmpty) {
            Map<String, dynamic>? latestEntry;
            int maxTs = 0;
            for (final item in entries) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                final ts = m['created_at'];
                final int curTs = ts is int ? ts : 0;
                if (curTs >= maxTs) {
                  maxTs = curTs;
                  latestEntry = m;
                }
              }
            }
            if (latestEntry != null) {
              final model = TelemetryModel.fromJson(latestEntry, isOnline: true);
              _controller.add(model);
              return model;
            }
          }
        }
      }
    } catch (_) {
      // Firebase RTDB juga unreachable / timeout
    }

    // 3. Status OFFLINE: Kedua jalur gagal terhubung (REL-03)
    final offlineSim = _generateOfflineTelemetry();
    _controller.add(offlineSim);
    return offlineSim;
  }

  TelemetryModel _generateOfflineTelemetry() {
    final now = DateTime.now();
    return TelemetryModel(
      temperature: 25.8 + (now.second % 5) * 0.1,
      humidity: 57.0 + (now.second % 3),
      mq7CoPpm: 5 + (now.second % 2),
      mq2SmokePpm: 110 + (now.second % 10),
      mq7Volt: 0.31,
      mq7Raw: 370,
      nodeId: nodeId,
      status: 'OFFLINE',
      timestamp: now,
      isOnline: false,
    );
  }

  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
