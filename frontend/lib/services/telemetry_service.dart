import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/telemetry_model.dart';

/// Service untuk mengambil data telemetri ESS via FastAPI Gateway (Single Gateway)
/// dengan secondary fallback ke Firebase RTDB buffer dan Heartbeat Watchdog 15 detik (TD-F17)
class TelemetryService {
  String backendUrl = ApiConstants.defaultBackendApiUrl;
  String firebaseUrl = ApiConstants.defaultFirebaseRtdbUrl;
  String nodeId = ApiConstants.defaultNodeId;

  final _controller = StreamController<TelemetryModel>.broadcast();
  Timer? _pollingTimer;
  TelemetryModel? _lastKnownModel;

  Stream<TelemetryModel> get telemetryStream => _controller.stream;

  void startPolling({Duration interval = ApiConstants.pollingInterval}) {
    _pollingTimer?.cancel();
    fetchLatest();
    _pollingTimer = Timer.periodic(interval, (_) => fetchLatest());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<TelemetryModel> fetchLatest() async {
    const int heartbeatTimeoutMs = 15000;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Jalur Utama: FastAPI Single Gateway (TD-F02)
    try {
      final cleanBase = backendUrl.replaceAll(RegExp(r'/+$'), '');
      final endpoint = Uri.parse('$cleanBase/api/telemetry/latest?device_id=$nodeId');
      final res = await http.get(
        endpoint,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded != null && decoded is Map<String, dynamic>) {
          if (decoded['status'] == 'success' || decoded['temperature_celsius'] != null || decoded['temp'] != null) {
            final int recordTs = _extractTimestampMs(decoded);
            final bool isFresh = recordTs > 0 && (nowMs - recordTs).abs() <= heartbeatTimeoutMs;

            final model = TelemetryModel.fromJson(decoded, isOnline: isFresh);
            _lastKnownModel = model;
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
                final curTs = _extractTimestampMs(m);
                if (curTs >= maxTs) {
                  maxTs = curTs;
                  latestEntry = m;
                }
              }
            }

            if (latestEntry != null) {
              // Validasi Heartbeat Watchdog 15 detik (TD-F17): Alat aktif hanya jika data < 15 detik
              final bool isFresh = maxTs > 0 && (nowMs - maxTs).abs() <= heartbeatTimeoutMs;
              final model = TelemetryModel.fromJson(latestEntry, isOnline: isFresh);
              _lastKnownModel = model;
              _controller.add(model);
              return model;
            }
          }
        }
      }
    } catch (_) {
      // Firebase RTDB juga unreachable / timeout
    }

    // 3. Status OFFLINE Murni (Nol Simulasi Palsu): Kedua jalur gagal atau alat mati
    final offlineModel = (_lastKnownModel != null)
        ? _lastKnownModel!.copyWith(isOnline: false, status: 'OFFLINE')
        : TelemetryModel.initial();

    _controller.add(offlineModel);
    return offlineModel;
  }

  int _extractTimestampMs(Map data) {
    final ts = data['created_at'] ?? data['timestamp'];
    if (ts is int) {
      return ts > 1000000000000 ? ts : ts * 1000;
    } else if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
      final numVal = int.tryParse(ts);
      if (numVal != null) return numVal > 1000000000000 ? numVal : numVal * 1000;
    }
    return 0;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
