import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/config.dart';
import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate that required compile-time config values were provided.
  if (kReleaseMode) {
    if (AppConfig.supabaseUrl.isEmpty ||
        !AppConfig.supabaseUrl.startsWith('https://')) {
      throw StateError(
        'SUPABASE_URL must be a valid HTTPS URL in release mode. '
        'Run with --dart-define=SUPABASE_URL=https://...',
      );
    }
    if (AppConfig.supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY is not set for release mode. '
        'Run with --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
      );
    }
    // Validate release API_BASE_URL (must be HTTPS and not localhost)
    AppConfig.apiBaseUrl;
  } else {
    assert(
      AppConfig.supabaseUrl.isNotEmpty,
      'SUPABASE_URL is not set. '
      'Run with --dart-define=SUPABASE_URL=https://...',
    );
    assert(
      AppConfig.supabasePublishableKey.isNotEmpty,
      'SUPABASE_PUBLISHABLE_KEY is not set. '
      'Run with --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
    );
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    // PKCE flow — authCallbackUrlHostname matches the deep-link host.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(
    // ProviderScope is required for Riverpod.
    const ProviderScope(child: Health360App()),
  );
}

class Health360App extends ConsumerWidget {
  const Health360App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Health360 AI',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
