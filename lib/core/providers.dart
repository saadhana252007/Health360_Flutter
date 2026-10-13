import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/supabase_client.dart';

// ── Dio / ApiClient providers ──────────────────────────────────────────────────

/// Provides the configured [Dio] instance (single instance per app lifetime).
final dioProvider = Provider<Dio>((ref) => buildApiClient());

/// Provides the [ApiClient] wrapper around [Dio].
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

// ── Supabase convenience provider ─────────────────────────────────────────────

/// Re-exports the Supabase client so repositories can depend on a provider
/// instead of the global accessor, making them easier to mock in tests.
final supabaseClientProvider = Provider((ref) => supabase);
