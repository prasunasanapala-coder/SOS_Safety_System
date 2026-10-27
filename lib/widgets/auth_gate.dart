import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import 'state_views.dart';

/// Chooses the first real screen: loading, login, or home.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: LoadingView(label: 'Checking sign-in...'));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const HomeScreen();
    }
  }
}

/// Wraps every private route so a signed-out user (for example one who typed
/// a URL in the browser) sees the login screen instead of private data.
class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: LoadingView(label: 'Checking sign-in...'));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return child;
    }
  }
}