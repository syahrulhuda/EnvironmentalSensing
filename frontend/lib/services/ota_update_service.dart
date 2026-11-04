import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../core/constants/api_constants.dart';
import '../models/app_version_model.dart';

/// Service untuk menangani In-App OTA Update Engine pada Flutter Mobile (DEVOPS-04)
/// Terintegrasi dengan endpoint FastAPI GET /api/app/version
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

  /// Membandingkan 2 string Semantic Versioning (misal target "2.1.0" > current "2.0.0")
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

  /// Unduh APK ke cache lokal internal dengan callback streaming progress
  static Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
    required void Function(String error) onError,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        onError('Gagal mengunduh APK (HTTP ${response.statusCode})');
        return;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      // Direktori cache internal aplikasi (aman dari permission constraint Android 11+)
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/app-update.apk');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      final sink = targetFile.openWrite();

      await response.stream.listen((chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }).asFuture();

      await sink.close();
      client.close();

      // Pemicu Android PackageInstaller bawaan via FileProvider content:// URI
      final openResult = await OpenFilex.open(
        targetFile.path,
        type: 'application/vnd.android.package-archive',
      );

      if (openResult.type != ResultType.done) {
        onError('Gagal memicu instalasi: ${openResult.message}');
      }
    } catch (e) {
      onError('Terjadi kesalahan download: $e');
    }
  }
}
