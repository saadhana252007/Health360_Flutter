import 'package:flutter/foundation.dart';

/// Application configuration.
///
/// Values are injected at compile time via `--dart-define`:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://... \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=... \
///     --dart-define=API_BASE_URL=https://...
///
/// The publishable (anon) key is safe to embed in the client binary.
/// The Supabase *secret* key must never appear here.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Base URL for the Health360 FastAPI backend.
  ///
  /// - In release mode (`kReleaseMode`), this must be explicitly supplied via
  ///   `--dart-define=API_BASE_URL=https://...` and must use HTTPS. Insecure HTTP
  ///   schemes and localhost/emulator loopback addresses are strictly rejected.
  /// - In debug/profile/test modes, falls back to `http://10.0.2.2:8000` (Android emulator)
  ///   if no custom URL is provided.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      if (kReleaseMode) {
        final uri = Uri.tryParse(fromEnv);
        final host = uri?.host.toLowerCase() ?? '';
        if (uri == null || uri.scheme != 'https' || host.isEmpty) {
          throw StateError(
            'In release mode, API_BASE_URL must be a valid HTTPS URL with a '
            'non-empty host (got: "$fromEnv"). '
            'Pass a production URL via --dart-define=API_BASE_URL=https://...',
          );
        }
        // Reject localhost, loopback (IPv4/IPv6), and Android-emulator addresses.
        const _blockedHosts = {
          'localhost',
          '127.0.0.1',
          '::1',
          '10.0.2.2', // Android emulator host alias
        };
        if (_blockedHosts.contains(host)) {
          throw StateError(
            'In release mode, API_BASE_URL cannot point to a local or emulator '
            'address (got: "$fromEnv"). '
            'Pass a production HTTPS domain via --dart-define=API_BASE_URL=https://...',
          );
        }
      }
      return fromEnv;
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is not set for release build. '
        'Pass --dart-define=API_BASE_URL=https://<your-backend-domain>',
      );
    }

    return 'http://10.0.2.2:8000';
  }
}
