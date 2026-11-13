import 'package:flutter_test/flutter_test.dart';
import 'package:environmental_sensing_frontend/services/telemetry_service.dart';

void main() {
  group('TelemetryService heartbeat watchdog', () {
    const int baseNowMs = 1794558512000;

    test('online when created_at epoch ms is within 15 seconds', () {
      final payload = {
        'status': 'success',
        'temperature_celsius': 28.0,
        'created_at': baseNowMs - 3000,
      };
      expect(
        TelemetryService.isGatewayPayloadOnline(payload, nowMs: baseNowMs),
        isTrue,
      );
    });

    test('online via is_online and age_seconds when timestamps are omitted', () {
      final payload = {
        'status': 'success',
        'temperature_celsius': 28.0,
        'is_online': true,
        'age_seconds': 4,
      };
      expect(
        TelemetryService.isGatewayPayloadOnline(payload, nowMs: baseNowMs),
        isTrue,
      );
    });

    test('offline when age_seconds exceeds 15s timeout even if backend says is_online true', () {
      final payload = {
        'status': 'success',
        'temperature_celsius': 28.0,
        'is_online': true,
        'age_seconds': 18,
        'created_at': baseNowMs - 18000,
      };
      expect(
        TelemetryService.isGatewayPayloadOnline(payload, nowMs: baseNowMs),
        isFalse,
      );
    });

    test('offline when is_online is false and timestamp is omitted', () {
      final payload = {
        'status': 'success',
        'temperature_celsius': 28.0,
        'is_online': false,
        'age_seconds': 60,
      };
      expect(
        TelemetryService.isGatewayPayloadOnline(payload, nowMs: baseNowMs),
        isFalse,
      );
    });
  });
}

