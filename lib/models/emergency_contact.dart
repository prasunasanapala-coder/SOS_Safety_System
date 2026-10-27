/// An emergency contact stored at `users/{uid}/emergencyContacts/{id}`.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
    this.createdAt,
  });

  /// Firestore document id. Empty for a contact that has not been saved yet.
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final DateTime? createdAt;

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt,
    );
  }

  /// Fields written to Firestore. Timestamps are added by the repository.
  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'isPrimary': isPrimary,
      };

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      relationship: (map['relationship'] as String?) ?? '',
      isPrimary: (map['isPrimary'] as bool?) ?? false,
      createdAt: map['createdAt'] is DateTime ? map['createdAt'] as DateTime : null,
    );
  }
}