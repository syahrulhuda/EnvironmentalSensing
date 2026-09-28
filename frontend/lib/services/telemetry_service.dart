import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/telemetry_model.dart';

/// Service untuk mengambil data telemetri dari Firebase RTDB (Hot Buffer)
class TelemetryService {
  String firebaseUrl = ApiConstants.defaultFirebaseRtdbUrl;
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
    try {
      final res = await http.get(Uri.parse(firebaseUrl)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded != null && decoded is Map) {
          final entries = decoded.values.toList();
          if (entries.isNotEmpty) {
            final latestJson = Map<String, dynamic>.from(entries.last as Map);
            final model = TelemetryModel.fromJson(latestJson);
            _controller.add(model);
            return model;
          }
        }
      }
    } catch (_) {
      // Fallback ke simulasi jika koneksi timeout / offline
      final simulated = _generateSimulatedTelemetry();
      _controller.add(simulated);
      return simulated;
    }
    return null;
  }

  TelemetryModel _generateSimulatedTelemetry() {
    final now = DateTime.now();
    return TelemetryModel(
      temperature: 25.8 + (now.second % 5) * 0.1,
      humidity: 57.0 + (now.second % 3),
      mq7CoPpm: 5 + (now.second % 2),
      mq2SmokePpm: 110 + (now.second % 10),
      mq7Volt: 0.31,
      mq7Raw: 370,
      nodeId: ApiConstants.defaultNodeId,
      status: 'NORMAL',
      timestamp: now,
    );
  }

  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
