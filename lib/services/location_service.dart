import '../models/location_models.dart';

/// Contract for reading the device location.
abstract class LocationService {
  /// Checks that location services are on, requests permission if needed, and
  /// returns the current position. Throws [LocationException] on failure.
  Future<AppPosition> getCurrentPosition();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}