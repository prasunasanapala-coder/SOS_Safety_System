import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_models.dart';
import 'location_service.dart';

/// Location access through the `geolocator` package.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<AppPosition> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'Location services are turned off on this device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Shows the system permission dialog.
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationFailure.denied,
        'Location permission was denied.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailure.deniedForever,
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return AppPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        accuracyMeters: position.accuracy,
      );
    } on TimeoutException {
      throw const LocationException(
        LocationFailure.unavailable,
        'Could not get a location fix in time. Try again outdoors.',
      );
    } catch (e) {
      debugPrint('Location error: $e');
      throw const LocationException(
        LocationFailure.unavailable,
        'Your location is currently unavailable.',
      );
    }
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}