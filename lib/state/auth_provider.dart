import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the current Supabase [Session] (or null when signed out).
///
/// The [GoRouter] redirect guard listens to this provider to enforce
/// authentication. Later items (login, register, logout) will interact with
/// the Supabase auth client directly; this provider just observes the state.
final authSessionProvider = StreamProvider<Session?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.session,
  );
});
