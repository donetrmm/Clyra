import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/change_master_password_page.dart';
import '../../features/auth/presentation/pages/session_settings_page.dart';
import '../../features/passwords/presentation/pages/home_page.dart';
import '../../features/passwords/presentation/pages/add_password_page.dart';
import '../../features/passwords/presentation/pages/edit_password_page.dart';
import '../../features/passwords/domain/entities/password_entry.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addPassword = '/add-password';
  static const String editPassword = '/edit-password';
  static const String changeMasterPassword = '/change-master-password';
  static const String sessionSettings = '/session-settings';

  // GlobalKey para acceder al router desde cualquier lugar
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static GoRouter? _router;

  static GoRouter createRouter(AuthViewModel authViewModel) {
    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: splash,
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final isLoggedIn = authViewModel.isLoggedIn;
        final hasSessionExpired = authViewModel.hasSessionExpired;

        // Si la sesión expiró, forzar navegación al login
        if (hasSessionExpired) {
          debugPrint('AppRouter: Sesión expirada, redirigiendo al login');
          return login;
        }

        // Redirección normal para usuarios no autenticados
        if (!isLoggedIn &&
            state.matchedLocation != splash &&
            state.matchedLocation != login &&
            state.matchedLocation != register) {
          return login;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),

        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: register,
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),

        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: addPassword,
          name: 'addPassword',
          builder: (context, state) => const AddPasswordPage(),
        ),
        GoRoute(
          path: editPassword,
          name: 'editPassword',
          builder: (context, state) {
            final password = state.extra as PasswordEntry?;
            if (password == null) {
              return const HomePage();
            }
            return EditPasswordPage(password: password);
          },
        ),
        GoRoute(
          path: changeMasterPassword,
          name: 'changeMasterPassword',
          builder: (context, state) => const ChangeMasterPasswordPage(),
        ),
        GoRoute(
          path: sessionSettings,
          name: 'sessionSettings',
          builder: (context, state) => const SessionSettingsPage(),
        ),
      ],
      errorBuilder:
          (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Página no encontrada',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(home),
                    child: const Text('Ir al inicio'),
                  ),
                ],
              ),
            ),
          ),
    );

    return _router!;
  }

  /// Método estático para navegar al login cuando la sesión expire
  static void navigateToLogin() {
    if (_router != null) {
      debugPrint('AppRouter: Navegando al login...');
      _router!.go(login);
    }
  }

  /// Getter para obtener el contexto actual
  static BuildContext? get currentContext => _rootNavigatorKey.currentContext;
}
