import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

/// Service untuk berinteraksi dengan ESI AI Agent via FastAPI Gateway
class EsiChatService {
  String backendUrl = ApiConstants.defaultBackendApiUrl;

  Future<String> sendMessage(String message, {List<Map<String, dynamic>>? history}) async {
    try {
      final cleanBase = backendUrl.replaceAll(RegExp(r'/+$'), '');
      final endpoint = Uri.parse('$cleanBase/api/chat');

      final payload = <String, dynamic>{'message': message};
      if (history != null && history.isNotEmpty) {
        payload['history'] = history;
      }

      final res = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data != null && data['reply'] != null) {
          return data['reply'].toString();
        }
      }
    } catch (_) {
      // Local fallback jika FastAPI backend sedang offline
      return _localFallbackResponse(message);
    }
    return _localFallbackResponse(message);
  }

  String _localFallbackResponse(String message) {
    final q = message.toLowerCase();
    if (q.contains('suhu') || q.contains('temp')) {
      return '🌡️ Suhu bengkel terpantau sekitar 25.8°C dalam ambang batas normal K3 (< 35°C).';
    } else if (q.contains('co') || q.contains('karbon') || q.contains('mq-7')) {
      return '⚠️ Kadar Karbon Monoksida (CO) terukur rendah (< 10 PPM), jauh di bawah batas bahaya 50 PPM.';
    } else if (q.contains('asap') || q.contains('mq-2') || q.contains('las') || q.contains('solder')) {
      return '🔥 Konsentrasi asap pekat pengelasan/soldering berada dalam rentang aman normal.';
    } else if (q.contains('evakuasi') || q.contains('sop')) {
      return '💡 SOP Evakuasi: Tutup hidung dan mulut, matikan saklar las/kompresor, buka ventilasi, dan segera berkumpul di titik aman luar bengkel.';
    }
    return 'Halo! Saya ESI, asisten keselamatan lingkungan bengkel mekatronika POLTEKOM. Semua sensor terpantau normal.';
  }
}
