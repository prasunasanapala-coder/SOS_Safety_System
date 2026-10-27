import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'auth_service.dart';

/// Firebase Authentication (email + password) implementation.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email, displayName: user.displayName);
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toAppUser);

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    // ignore: body_might_complete_normally_nullable
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(displayName.trim());
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Converts Firebase exceptions into messages a user can understand.
  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code}');
      throw AuthFailure(_messageFor(e.code));
    } catch (e) {
      debugPrint('Auth error: $e');
      throw const AuthFailure('Something went wrong. Please try again.');
    }
  }

  static String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'That password is too weak. Use at least 8 characters.';
      case 'network-request-failed':
        return 'No network connection. Check your internet and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in the Firebase Console.';
      default:
        return 'Authentication failed ($code).';
    }
  }
}