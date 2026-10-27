/// A position reading. Whether it is real or demonstration data is tracked by
/// the provider that holds it, never guessed from the values.
class AppPosition {
  const AppPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracyMeters;

  /// Documented Google Maps URL format that opens a pin at the coordinates.
  Uri get mapUri => Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$latitude,$longitude',
      });

  String get coordinatesText =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

enum LocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class LocationException implements Exception {
  const LocationException(this.failure, this.message);

  final LocationFailure failure;
  final String message;

  @override
  String toString() => message;
}