class SosEvent {
  final String id;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final String locationUrl;
  final String status;
  final String message;
  final List<String> contactsNotified;

  SosEvent({
    required this.id,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.locationUrl,
    required this.status,
    required this.message,
    required this.contactsNotified,
  });

  factory SosEvent.fromMap(String id, Map<String, dynamic> map) {
    return SosEvent(
      id: id,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
      latitude: (map['latitude'] ?? 0.0) is num
          ? (map['latitude'] as num).toDouble()
          : 0.0,
      longitude: (map['longitude'] ?? 0.0) is num
          ? (map['longitude'] as num).toDouble()
          : 0.0,
      locationUrl: (map['locationUrl'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      message: (map['message'] ?? '').toString(),
      contactsNotified: (map['contactsNotified'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'latitude': latitude,
      'longitude': longitude,
      'locationUrl': locationUrl,
      'status': status,
      'message': message,
      'contactsNotified': contactsNotified,
    };
  }
}
