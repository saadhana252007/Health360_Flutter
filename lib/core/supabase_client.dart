import 'package:supabase_flutter/supabase_flutter.dart';

/// Convenience accessor for the Supabase client.
///
/// Supabase is initialized in [main] before [runApp] is called, so this
/// is always safe to use after initialization.
SupabaseClient get supabase => Supabase.instance.client;
