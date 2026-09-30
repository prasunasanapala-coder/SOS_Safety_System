import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  Position? currentPosition;
  bool isLocationServiceEnabled = false;
  String? errorMessage;

  Future<bool> ensureLocationReady() async {
    try {
      isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        errorMessage =
            'Location services are disabled. Please enable GPS to continue.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage = 'Location permission is permanently denied. Please enable it in settings.';
        notifyListeners();
        return false;
      }

      if (permission == LocationPermission.denied) {
        errorMessage = 'Location permission was denied. Please allow location access to send SOS alerts.';
        notifyListeners();
        return false;
      }

      currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  String buildMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }
}
