/// Profile and safety preferences stored at `users/{uid}`.
///
/// The e-mail address is *not* stored here: Firebase Authentication already
/// holds it, so we keep personal data in Firestore to a minimum.
class UserProfile {
  const UserProfile({
    required this.displayName,
    this.demoMode = true,
    this.emergencyNumber = defaultEmergencyNumber,
    this.countdownSeconds = defaultCountdown,
  });

  /// Public emergency number used for the dialer shortcut. It is editable in
  /// Settings because it differs between countries.
  static const String defaultEmergencyNumber = '112';
  static const int defaultCountdown = 5;
  static const int minCountdown = 3;
  static const int maxCountdown = 10;

  final String displayName;

  /// Demo mode is ON by default: the app never opens the dialer or message
  /// app and never contacts anybody.
  final bool demoMode;
  final String emergencyNumber;
  final int countdownSeconds;

  factory UserProfile.defaults({String displayName = 'Friend'}) =>
      UserProfile(displayName: displayName);

  UserProfile copyWith({
    String? displayName,
    bool? demoMode,
    String? emergencyNumber,
    int? countdownSeconds,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      demoMode: demoMode ?? this.demoMode,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'demoMode': demoMode,
        'emergencyNumber': emergencyNumber,
        'countdownSeconds': countdownSeconds,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final seconds = (map['countdownSeconds'] as num?)?.toInt() ?? defaultCountdown;
    return UserProfile(
      displayName: (map['displayName'] as String?) ?? 'Friend',
      demoMode: (map['demoMode'] as bool?) ?? true,
      emergencyNumber:
          (map['emergencyNumber'] as String?) ?? defaultEmergencyNumber,
      countdownSeconds: seconds.clamp(minCountdown, maxCountdown),
    );
  }
}