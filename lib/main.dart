import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/config.dart';
import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate that the required compile-time config values were provided.
  // An empty string means the --dart-define flag was not passed.
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
    const ProviderScope(
      child: Health360App(),
    ),
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
