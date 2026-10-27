/// Outcome of an SOS workflow run.
///
/// These are *local records of what the app did*. They never mean that an SMS,
/// call or notification was delivered to anybody.
enum SosStatus {
  initiated,
  cancelled;

  static SosStatus fromName(String? name) {
    return SosStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => SosStatus.cancelled,
    );
  }

  String get label =>
      this == SosStatus.initiated ? 'Alert initiated (prototype)' : 'Cancelled';
}

/// A record stored at `users/{uid}/sosHistory/{id}`.
class SosRecord {
  const SosRecord({
    required this.id,
    required this.status,
    required this.demoMode,
    required this.contactCount,
    required this.locationShared,
    this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final SosStatus status;
  final bool demoMode;
  final int contactCount;
  final bool locationShared;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'demoMode': demoMode,
        'contactCount': contactCount,
        'locationShared': locationShared,
        if (latitude != null && longitude != null) ...{
          'latitude': latitude,
          'longitude': longitude,
        },
      };

  factory SosRecord.fromMap(String id, Map<String, dynamic> map) {
    return SosRecord(
      id: id,
      status: SosStatus.fromName(map['status'] as String?),
      demoMode: (map['demoMode'] as bool?) ?? true,
      contactCount: (map['contactCount'] as num?)?.toInt() ?? 0,
      locationShared: (map['locationShared'] as bool?) ?? false,
      createdAt: map['createdAt'] is DateTime ? map['createdAt'] as DateTime : null,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}