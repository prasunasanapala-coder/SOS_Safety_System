import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/user_profile.dart';
import '../services/data_repository.dart';
import '../services/local_storage_service.dart';
import 'op_result.dart';

/// Profile, safety preferences (cloud) and theme (device).
class SettingsProvider extends ChangeNotifier with SafeNotifier {
    SettingsProvider({
    required this._repository,
    required LocalStorageService storage,
  })  : _storage = storage,
        _themeMode = storage.themeMode;
  final DataRepository _repository;
  final LocalStorageService _storage;

  String? _uid;
  ThemeMode _themeMode;
  UserProfile _profile = UserProfile.defaults();
  bool _loading = false;
  String? _error;

  ThemeMode get themeMode => _themeMode;
  UserProfile get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;
  bool get demoMode => _profile.demoMode;

  /// Called whenever the signed-in user changes.
  void setUser(AppUser? user, {String? fallbackName}) {
    if (user?.uid == _uid) return;
    _uid = user?.uid;
    _profile = UserProfile.defaults();
    _error = null;
    if (user == null) {
      _loading = false;
      notifyLater();
      return;
    }
    _loading = true;
    notifyLater();
    unawaited(_load(user, fallbackName));
  }

  Future<void> _load(AppUser user, String? fallbackName) async {
    final uid = user.uid;
    try {
      final stored = await _repository.getProfile(uid).timeout(const Duration(seconds: 10));
      if (_uid != uid || isDisposed) return;
      if (stored != null) {
        _profile = stored;
      } else {
        final name = _firstNonEmpty([user.displayName, fallbackName]) ??
            _nameFromEmail(user.email);
        _profile = UserProfile.defaults(displayName: name);
        // Create the profile document; failures are shown on next save.
        await _repository.saveProfile(uid, _profile).catchError((Object e) {
          debugPrint('Initial profile save failed: $e');
        });
      }
    } catch (e) {
      if (_uid != uid || isDisposed) return;
      debugPrint('Profile load failed: $e');
      _error = 'Could not load your profile. Using default settings.';
      _profile = UserProfile.defaults(
        displayName: _firstNonEmpty([user.displayName, fallbackName]) ??
            _nameFromEmail(user.email),
      );
    } finally {
      if (_uid == uid) {
        _loading = false;
        notifySafely();
      }
    }
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String _nameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return 'Friend';
    return email.split('@').first;
  }

  Future<OpResult> saveProfile(UserProfile updated) async {
    final uid = _uid;
    if (uid == null) return const OpResult(false, 'You are not signed in.');
    final previous = _profile;
    _profile = updated; // optimistic update so the UI responds instantly
    notifySafely();
    final result = await runOp(
      () => _repository.saveProfile(uid, updated),
      'Settings saved.',
    );
    if (!result.ok) {
      _profile = previous;
      notifySafely();
    }
    return result;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifySafely();
    await _storage.setThemeMode(mode);
  }
}