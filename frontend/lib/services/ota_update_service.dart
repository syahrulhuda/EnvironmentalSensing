import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/api_constants.dart';
import '../models/app_version_model.dart';

/// Service untuk menangani OTA Update Check pada Flutter Mobile (DEVOPS-04)
/// Terintegrasi dengan endpoint FastAPI GET /api/app/version dan aman dari Play Protect
class OtaUpdateService {
  /// Cek versi terbaru ke backend FastAPI Single Gateway
  static Future<AppVersionModel?> checkForUpdate() async {
    if (kIsWeb) return null;
    try {
      if (!Platform.isAndroid) return null;
    } catch (_) {
      return null;
    }

    try {
      final endpoint = Uri.parse('${ApiConstants.defaultBackendApiUrl}/api/app/version');
      final res = await http.get(endpoint, headers: {
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body) as Map<String, dynamic>;
        final remote = AppVersionModel.fromJson(decoded);

        final packageInfo = await PackageInfo.fromPlatform();
        // Bersihkan build number (misal 2.0.0+1 -> 2.0.0)
        final localVersion = packageInfo.version.split('+').first.trim();

        if (_isVersionNewer(localVersion, remote.latestVersion)) {
          return remote;
        }
      }
    } catch (e) {
      // Fail-Safe: Jika server offline, biarkan aplikasi berjalan normal tanpa crash
      debugPrint('[OTA Update] Check skipped: $e');
    }
    return null;
  }

  /// Membandingkan 2 string Semantic Versioning (misal target "2.2.3" > current "2.2.2")
  static bool _isVersionNewer(String current, String target) {
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final tParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < cParts.length ? cParts[i] : 0;
      final t = i < tParts.length ? tParts[i] : 0;
      if (t > c) return true;
      if (t < c) return false;
    }
    return false;
  }

  /// Buka halaman download rilis di browser eksternal (Solusi Bersih Play Protect)
  static Future<bool> openDownloadPage(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[OTA Update] Launch URL error: $e');
      return false;
    }
  }
}
