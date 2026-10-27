import 'package:flutter/foundation.dart';

import '../models/location_models.dart';
import '../services/location_service.dart';

enum LocationStatus { idle, loading, ready, denied, deniedForever, serviceOff, error }

/// State for the Location screen.
class LocationProvider extends ChangeNotifier {
  LocationProvider(this._service);

  final LocationService _service;

  /// Fixed demonstration coordinates (central New Delhi, a public place). They
  /// are NOT the user's location and the UI labels them that way.
  static final AppPosition demoPosition = AppPosition(
    latitude: 28.6139,
    longitude: 77.2090,
    timestamp: DateTime.utc(2026, 1, 1),
  );

  LocationStatus _status = LocationStatus.idle;
  AppPosition? _position;
  bool _isDemo = false;
  String? _message;

  LocationStatus get status => _status;
  AppPosition? get position => _position;

  /// True when [position] is demonstration data rather than a real reading.
  bool get isDemo => _isDemo;
  String? get message => _message;

  /// Must be triggered by an explicit user action (button press).
  Future<void> fetch() async {
    _status = LocationStatus.loading;
    _message = null;
    notifyListeners();
    try {
      _position = await _service.getCurrentPosition();
      _isDemo = false;
      _status = LocationStatus.ready;
    } on LocationException catch (e) {
      _position = null;
      _message = e.message;
      switch (e.failure) {
        case LocationFailure.serviceDisabled:
          _status = LocationStatus.serviceOff;
        case LocationFailure.denied:
          _status = LocationStatus.denied;
        case LocationFailure.deniedForever:
          _status = LocationStatus.deniedForever;
        case LocationFailure.unavailable:
          _status = LocationStatus.error;
      }
    } catch (e) {
      debugPrint('Unexpected location error: $e');
      _position = null;
      _message = 'Your location is currently unavailable.';
      _status = LocationStatus.error;
    }
    notifyListeners();
  }

  void useDemoLocation() {
    _position = demoPosition;
    _isDemo = true;
    _message = null;
    _status = LocationStatus.ready;
    notifyListeners();
  }

  Future<void> openAppSettings() => _service.openAppSettings();

  Future<void> openLocationSettings() => _service.openLocationSettings();
}