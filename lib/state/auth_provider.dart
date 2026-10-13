import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the stream of [AuthState] events from Supabase.
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Exposes the current Supabase [Session] (or null when signed out).
///
/// The [GoRouter] redirect guard listens to this provider to enforce
/// authentication.
final authSessionProvider = StreamProvider<Session?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session,
  );
});

/// Exposes the current Supabase [User] (or null when signed out or uninitialized).
final currentUserProvider = Provider<User?>((ref) {
  try {
    return Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return null;
  }
});

/// Tracks whether the app is currently in password-recovery mode.
///
/// When an [AuthChangeEvent.passwordRecovery] event arrives from a deep link,
/// this is set to `true` to ensure the recovery session is never mistaken
/// for a normal login and redirected away from [ResetPasswordScreen].
final isPasswordRecoveryProvider = StateProvider<bool>((ref) => false);

/// Listens to auth state changes to detect recovery and sign-out events.
final authStateListenerProvider = Provider<void>((ref) {
  final subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
    data,
  ) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      ref.read(isPasswordRecoveryProvider.notifier).state = true;
    } else if (data.event == AuthChangeEvent.signedOut) {
      ref.read(isPasswordRecoveryProvider.notifier).state = false;
    }
  });
  ref.onDispose(subscription.cancel);
});
