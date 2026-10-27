import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small on-device settings stored with SharedPreferences.
///
/// Only non-sensitive conveniences live here: theme, favourite tip ids and
/// whether onboarding was seen. Contacts and SOS history are in Firestore.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'theme_mode';
  static const _favoritesKey = 'favorite_tip_ids';
  static const _onboardingKey = 'onboarding_seen';

  ThemeMode get themeMode {
    switch (_prefs.getString(_themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode.name);

  Set<String> get favoriteTipIds =>
      (_prefs.getStringList(_favoritesKey) ?? const <String>[]).toSet();

  Future<void> setFavoriteTipIds(Set<String> ids) =>
      _prefs.setStringList(_favoritesKey, ids.toList());

  bool get onboardingSeen => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  /// Removes everything this app stored on the device.
  Future<void> clearAll() => _prefs.clear();
}