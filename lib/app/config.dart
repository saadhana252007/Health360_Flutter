/// Application configuration.
///
/// Values are injected at compile time via `--dart-define`:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://... \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=... \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// The publishable (anon) key is safe to embed in the client binary.
/// The Supabase *secret* key must never appear here.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Default: Android emulator reaches the host PC on 10.0.2.2.
    // On a physical device replace with your LAN IP, e.g. http://192.168.1.x:8000
    defaultValue: 'http://10.0.2.2:8000',
  );
}
