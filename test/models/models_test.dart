import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/models/emergency_contact.dart';
import 'package:sos_safety_system/models/safety_tip.dart';
import 'package:sos_safety_system/models/sos_record.dart';
import 'package:sos_safety_system/models/user_profile.dart';

void main() {
  group('SafetyTip.tryParse', () {
    test('parses a complete item', () {
      final tip = SafetyTip.tryParse({
        'id': 'p1',
        'category': 'Personal safety',
        'title': 'Share your plans',
        'body': 'Tell someone.',
      });
      expect(tip, isNotNull);
      expect(tip!.title, 'Share your plans');
    });

    test('returns null for malformed items', () {
      expect(SafetyTip.tryParse({'id': 'p1'}), isNull);
      expect(SafetyTip.tryParse('not a map'), isNull);
      expect(SafetyTip.tryParse(null), isNull);
    });
  });

  group('SosRecord', () {
    test('round trips through toMap/fromMap', () {
      const record = SosRecord(
        id: '',
        status: SosStatus.initiated,
        demoMode: true,
        contactCount: 2,
        locationShared: true,
        latitude: 12.5,
        longitude: 77.5,
      );
      final copy = SosRecord.fromMap('x', record.toMap());
      expect(copy.status, SosStatus.initiated);
      expect(copy.contactCount, 2);
      expect(copy.latitude, 12.5);
      expect(copy.longitude, 77.5);
    });

    test('omits coordinates when no location was shared', () {
      const record = SosRecord(
        id: '',
        status: SosStatus.cancelled,
        demoMode: true,
        contactCount: 0,
        locationShared: false,
      );
      expect(record.toMap().containsKey('latitude'), isFalse);
    });

    test('unknown status names fall back to cancelled', () {
      expect(SosStatus.fromName('something-else'), SosStatus.cancelled);
    });
  });

  group('UserProfile', () {
    test('fromMap applies safe defaults', () {
      final profile = UserProfile.fromMap({});
      expect(profile.demoMode, isTrue);
      expect(profile.emergencyNumber, '112');
      expect(profile.countdownSeconds, 5);
    });

    test('countdown is clamped to the allowed range', () {
      expect(UserProfile.fromMap({'countdownSeconds': 99}).countdownSeconds, 10);
      expect(UserProfile.fromMap({'countdownSeconds': 0}).countdownSeconds, 3);
    });
  });

  test('EmergencyContact copyWith changes only the given fields', () {
    const contact = EmergencyContact(
      id: '1',
      name: 'Test Contact A',
      phone: '+10000000001',
      relationship: 'Friend',
    );
    final primary = contact.copyWith(isPrimary: true);
    expect(primary.isPrimary, isTrue);
    expect(primary.name, 'Test Contact A');
    expect(contact.isPrimary, isFalse);
  });
}