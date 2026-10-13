import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/shell/home_shell.dart';
import '../state/auth_provider.dart';

// ── Route paths ───────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  /// Opened by the `health360://login/reset` deep link.
  static const String resetPassword = '/login/reset';

  static const String home = '/home';
}

// ── Router provider ───────────────────────────────────────────────────────────

/// Provides a [GoRouter] whose [GoRouter.redirect] enforces authentication.
///
/// - Unauthenticated users are always sent to [AppRoutes.login].
/// - Authenticated users are redirected away from auth routes to [AppRoutes.home].
/// - While the session is still loading the splash screen is shown.
final routerProvider = Provider<GoRouter>((ref) {
  // Keep a Listenable that GoRouter can use to re-evaluate the redirect
  // whenever the session changes.
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,

    // ── Deep-link prefix for `health360://` scheme ────────────────────────────
    // GoRouter matches URIs, so we register the deep-link base here.
    // The Android intent filter (in AndroidManifest.xml) routes the URI into
    // the app; GoRouter then matches the path `/login/reset`.

    redirect: (BuildContext context, GoRouterState state) {
      final sessionAsync = ref.read(authSessionProvider);

      // Still waiting for Supabase to restore the session.
      if (sessionAsync.isLoading) {
        return AppRoutes.splash;
      }

      final isAuthenticated = sessionAsync.valueOrNull != null;
      final location = state.matchedLocation;

      // Deep-link: always allow the reset-password screen regardless of auth
      // state, because the user arrives with a recovery session (not a normal
      // session) — the ResetPasswordScreen must handle that distinction.
      if (location == AppRoutes.resetPassword) {
        return null;
      }

      if (!isAuthenticated) {
        // Unauthenticated — send to login (but not if already there).
        if (location == AppRoutes.login) return null;
        return AppRoutes.login;
      }

      // Authenticated — redirect away from auth screens.
      if (location == AppRoutes.login || location == AppRoutes.splash) {
        return AppRoutes.home;
      }

      return null; // No redirect needed.
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        // Also matched when the deep link `health360://login/reset` arrives.
        path: AppRoutes.resetPassword,
        builder: (context, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, _) => const HomeShell(),
      ),
    ],
  );
});

// ── Internal helper ───────────────────────────────────────────────────────────

/// A [Listenable] that notifies GoRouter whenever [authSessionProvider]
/// emits a new value (sign-in, sign-out, token refresh, etc.).
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authSessionProvider, (_, next) => notifyListeners());
  }
}
