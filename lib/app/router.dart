import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/shell/home_shell.dart';
import '../state/auth_provider.dart';

// ── Route paths ───────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  /// Opened by the `health360://login/reset` deep link.
  static const String resetPassword = '/login/reset';

  static const String home = '/home';
}

// ── Router provider ───────────────────────────────────────────────────────────

/// Provides a [GoRouter] whose [GoRouter.redirect] enforces authentication.
///
/// - Unauthenticated users can only access [AppRoutes.login] and [AppRoutes.register].
/// - Authenticated users are redirected away from auth routes to [AppRoutes.home].
/// - Password recovery sessions are routed to [AppRoutes.resetPassword] and
///   are never redirected to [AppRoutes.home].
/// - While the session is still loading the splash screen is shown.
final routerProvider = Provider<GoRouter>((ref) {
  // Activate the listener so recovery events are tracked.
  ref.watch(authStateListenerProvider);

  // Keep a Listenable that GoRouter can use to re-evaluate the redirect
  // whenever the session or recovery state changes.
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,

    // ── Deep-link prefix for `health360://` scheme ────────────────────────────
    // The Android intent filter routes the URI into the app; GoRouter matches
    // the path `/login/reset`.
    redirect: (BuildContext context, GoRouterState state) {
      final sessionAsync = ref.read(authSessionProvider);

      // Still waiting for Supabase to restore the session.
      if (sessionAsync.isLoading) {
        return AppRoutes.splash;
      }

      final isAuthenticated = sessionAsync.valueOrNull != null;
      final isRecovery = ref.read(isPasswordRecoveryProvider);
      final location = state.matchedLocation;

      // Deep-link / Password Recovery handling:
      // Always allow reset-password screen; if in recovery mode, never redirect to home.
      if (location == AppRoutes.resetPassword) {
        return null;
      }
      if (isRecovery) {
        return AppRoutes.resetPassword;
      }

      if (!isAuthenticated) {
        // Unauthenticated — allow login and register screens.
        if (location == AppRoutes.login || location == AppRoutes.register) {
          return null;
        }
        return AppRoutes.login;
      }

      // Authenticated with a normal session — redirect away from auth screens.
      if (location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.splash) {
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
        path: AppRoutes.register,
        builder: (context, _) => const RegisterScreen(),
      ),
      GoRoute(
        // Matched when the deep link `health360://login/reset` arrives.
        path: AppRoutes.resetPassword,
        builder: (context, _) => const ResetPasswordScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (context, _) => const HomeShell()),
    ],
  );
});

// ── Internal helper ───────────────────────────────────────────────────────────

/// A [Listenable] that notifies GoRouter whenever [authSessionProvider]
/// or [isPasswordRecoveryProvider] emits a new value.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AsyncValue<Session?>>(
      authSessionProvider,
      (_, _) => notifyListeners(),
    );
    ref.listen<bool>(isPasswordRecoveryProvider, (_, _) => notifyListeners());
  }
}
