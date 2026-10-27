import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'op_result.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Holds authentication state for the whole app (Experiment 5b: Provider).
class AuthProvider extends ChangeNotifier with SafeNotifier {
  AuthProvider(this._service) {
    _subscription = _service.authStateChanges().listen(
      _onUser,
      onError: (Object e) {
        debugPrint('Auth stream error: $e');
        _status = AuthStatus.signedOut;
        notifySafely();
      },
    );
  }

  final AuthService _service;
  StreamSubscription<AppUser?>? _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;
  String? _error;
  String? _pendingDisplayName;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get uid => _user?.uid;
  bool get busy => _busy;
  String? get error => _error;

  /// Name typed on the register form, used when the profile is first created.
  String? get pendingDisplayName => _pendingDisplayName;

  void _onUser(AppUser? user) {
    _user = user;
    _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifySafely();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifySafely();
  }

  Future<bool> signIn(String email, String password) {
    return _run(() => _service.signIn(email: email, password: password));
  }

  Future<bool> register(String email, String password, String displayName) {
    _pendingDisplayName = displayName.trim();
    return _run(() => _service.register(
          email: email,
          password: password,
          displayName: displayName,
        ));
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _service.sendPasswordReset(email));
  }

  Future<void> signOut() async {
    await _service.signOut();
    _pendingDisplayName = null;
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifySafely();
    try {
      await action();
      return true;
    } on AuthFailure catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifySafely();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}