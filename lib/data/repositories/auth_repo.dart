import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';

/// Handles Supabase Auth operations.
///
/// Login, register, and reset-password screens call this in items 3a–3c.
/// The repository is provided here so it can be tested and injected via
/// Riverpod without coupling screens to the Supabase singleton directly.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  // ── Session ──────────────────────────────────────────────────────────────────

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // ── Sign-in ──────────────────────────────────────────────────────────────────

  /// Signs the user in with email and password.
  ///
  /// Throws a [AuthException] from supabase_flutter on failure.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // ── Sign-up ──────────────────────────────────────────────────────────────────

  /// Registers a new user.
  ///
  /// Profile data is stored in [data] so a database trigger (Q1 fix) can
  /// create the `profiles` row even when email confirmation is enabled and
  /// no session is available immediately after sign-up.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> profileData,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: profileData, // used by the DB trigger (Q1 fix path)
    );
  }

  // ── Password reset ───────────────────────────────────────────────────────────

  /// Sends a password-reset email.
  ///
  /// The deep link `health360://login/reset` is listed in Supabase Dashboard →
  /// Authentication → URL Configuration → Redirect URLs.
  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'health360://login/reset',
    );
  }

  /// Updates the password for the currently authenticated user.
  ///
  /// Called from [ResetPasswordScreen] after the deep link delivers a recovery
  /// session. Uses 8+ characters (Q2 fix: both register and reset use the same
  /// 8-char minimum; the Kotlin app used 6 for reset which was a bug).
  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── Sign-out ─────────────────────────────────────────────────────────────────

  Future<void> signOut() => _client.auth.signOut();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(supabase);
});
