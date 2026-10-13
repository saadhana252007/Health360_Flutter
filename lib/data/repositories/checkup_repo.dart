import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/checkup_summary.dart';
import '../models/checkup_detail.dart';
import '../../core/supabase_client.dart';
import '../../core/providers.dart';
import '../../core/api_client.dart';

/// Handles Supabase reads from the `checkups` table and delegates
/// API submissions to [ApiClient].
///
/// Mirrors the read logic of Kotlin `CheckupRepository.kt` and
/// `CheckupDetailRepository.kt`.
///
/// ⚠️  The client does NOT write to `checkups`; the backend writes all rows.
class CheckupRepository {
  const CheckupRepository({
    required this.supabaseClient,
    required this.apiClient,
  });

  final SupabaseClient supabaseClient;
  final ApiClient apiClient;

  // ── Supabase reads ────────────────────────────────────────────────────────────

  /// Returns the most recent checkup for [userId], or null if none exists.
  ///
  /// Mirrors: `getLatestCheckup(userId)` — filter user_id, order created_at
  /// DESC, limit 1.
  Future<CheckupSummary?> getLatestCheckup(String userId) async {
    final rows = await supabaseClient
        .from('checkups')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return CheckupSummary.fromJson(rows.first);
  }

  /// Returns all checkups for [userId], newest first.
  ///
  /// Mirrors: `getCheckupHistory(userId)`.
  Future<List<CheckupSummary>> getCheckupHistory(String userId) async {
    final rows = await supabaseClient
        .from('checkups')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map((r) => CheckupSummary.fromJson(r)).toList();
  }

  /// Returns the full detail row for [checkupId] belonging to [userId], or null.
  ///
  /// Mirrors: `getCheckupDetail(checkupId, userId)` — filter both id and
  /// user_id so RLS is not the only guard.
  Future<CheckupDetail?> getCheckupDetail({
    required String checkupId,
    required String userId,
  }) async {
    final rows = await supabaseClient
        .from('checkups')
        .select()
        .eq('id', checkupId)
        .eq('user_id', userId)
        .limit(1);

    if (rows.isEmpty) return null;
    return CheckupDetail.fromJson(rows.first);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final checkupRepositoryProvider = Provider<CheckupRepository>((ref) {
  return CheckupRepository(
    supabaseClient: supabase,
    apiClient: ref.watch(apiClientProvider),
  );
});
