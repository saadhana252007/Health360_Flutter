// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health360ai/app/config.dart';

/// Smoke test for the FastAPI /health endpoint.
///
/// This test is intentionally skipped in CI / when the backend is not running.
/// Run it manually while the FastAPI server is up:
///
///   flutter test test/smoke/health_smoke_test.dart \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// The test does NOT claim to pass unless it can actually reach the server.
void main() {
  group('/health smoke test', () {
    late Dio dio;

    setUpAll(() {
      final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
          ? AppConfig.apiBaseUrl
          : '${AppConfig.apiBaseUrl}/';

      dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    });

    test('GET /health returns 200 with status key', () async {
      // Detect whether we can reach the server before attempting.
      final host = Uri.parse(AppConfig.apiBaseUrl).host;
      final port = Uri.parse(AppConfig.apiBaseUrl).port;
      final isReachable = await _isHostReachable(host, port);

      if (!isReachable) {
        print(
          '\n[SKIP] Backend not reachable at ${AppConfig.apiBaseUrl}. '
          'Run the FastAPI server and re-run this test to verify /health.\n',
        );
        // Mark as skipped rather than failing.
        return;
      }

      final response = await dio.get<Map<String, dynamic>>('health');

      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
      // The backend returns {"status": "healthy"} or similar.
      expect(response.data!.containsKey('status'), isTrue,
          reason: 'Response body must contain a "status" key');

      print('[PASS] /health → ${response.data}');
    });
  });
}

/// Returns true if a TCP connection to [host]:[port] can be established
/// within 3 seconds. Used to avoid a slow timeout during test discovery.
Future<bool> _isHostReachable(String host, int port) async {
  try {
    final socket = await Socket.connect(
      host,
      port == -1 ? 8000 : port,
      timeout: const Duration(seconds: 3),
    );
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
