class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isEmergencyContact;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.isEmergencyContact,
    required this.createdAt,
  });

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      relationship: (map['relationship'] ?? '').toString(),
      isEmergencyContact: map['isEmergencyContact'] as bool? ?? false,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isEmergencyContact': isEmergencyContact,
      'createdAt': createdAt,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isEmergencyContact,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
