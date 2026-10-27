import 'package:flutter/material.dart';

import '../screens/contact_form_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/location_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sos_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tips_screen.dart';
import '../widgets/auth_gate.dart';

/// Route names (Experiment 4b: named routes).
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String gate = '/gate';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String sos = '/sos';
  static const String contacts = '/contacts';
  static const String contactForm = '/contacts/form';
  static const String location = '/location';
  static const String tips = '/tips';
  static const String history = '/history';
  static const String settings = '/settings';
}

/// Maps route names to screens and adds the page transition.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case AppRoutes.splash:
        page = const SplashScreen();
      case AppRoutes.gate:
        page = const AuthGate();
      case AppRoutes.register:
        page = const RegisterScreen();
      case AppRoutes.resetPassword:
        page = const ResetPasswordScreen();
      // Everything below is private and wrapped by AuthGuard.
      case AppRoutes.home:
        page = const AuthGuard(child: HomeScreen());
      case AppRoutes.sos:
        page = const AuthGuard(child: SosScreen());
      case AppRoutes.contacts:
        page = const AuthGuard(child: ContactsScreen());
      case AppRoutes.contactForm:
        page = const AuthGuard(child: ContactFormScreen());
      case AppRoutes.location:
        page = const AuthGuard(child: LocationScreen());
      case AppRoutes.tips:
        page = const AuthGuard(child: TipsScreen());
      case AppRoutes.history:
        page = const AuthGuard(child: HistoryScreen());
      case AppRoutes.settings:
        page = const AuthGuard(child: SettingsScreen());
      default:
        page = const _NotFoundScreen();
    }
    return _fadeSlide(settings, page);
  }

  /// Fade + slide transition for every navigation (Experiment 8b).
  static PageRouteBuilder<dynamic> _fadeSlide(RouteSettings settings, Widget page) {
    return PageRouteBuilder<dynamic>(
      settings: settings, // keeps `arguments` available to the screen
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.gate, (route) => false),
          child: const Text('Go to start'),
        ),
      ),
    );
  }
}