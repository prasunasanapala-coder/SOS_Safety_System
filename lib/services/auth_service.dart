import '../models/app_user.dart';

/// Contract for authentication. The real implementation uses Firebase
/// Authentication; tests use a fake. Providers only know this interface.
abstract class AuthService {
  /// Emits the current user (or null) immediately, then on every change.
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

/// A user-friendly authentication error.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
