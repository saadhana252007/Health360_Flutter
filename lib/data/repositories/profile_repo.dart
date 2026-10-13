import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../../core/supabase_client.dart';

/// Handles reads and writes to the Supabase `profiles` table.
///
/// Mirrors Kotlin `ProfileRepository.kt`:
///   - `getProfile(userId)` → filter `id = userId`, decodeSingleOrNull
///   - `updateProfile(profile)` → update where `id = profile.id`
///
/// The client never INSERTs into `profiles` directly — the backend or a
/// database trigger (Q1 fix) handles row creation.
class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Fetches the profile for [userId], or null if it doesn't exist yet.
  Future<Profile?> getProfile(String userId) async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .limit(1);

    if (rows.isEmpty) return null;
    return Profile.fromJson(rows.first);
  }

  /// Upserts a profile row (INSERT on first login / UPDATE afterwards).
  ///
  /// Used by the Q1 fix path: if no `profiles` row exists after sign-in,
  /// create one from the User metadata.
  Future<void> upsertProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toJson());
  }

  /// Updates mutable fields (name, DOB, sex, height, weight) for an existing row.
  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase);
});
