class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      fullName: (map['name'] ?? map['fullName'] ?? 'Unknown User').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': fullName,
      'email': email,
      'phone': phone,
      'createdAt': createdAt,
    };
  }
}
