import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/utils/validators.dart';

void main() {
  group('phone', () {
    test('accepts digits with optional + and separators', () {
      expect(Validators.phone('+10000000001'), isNull);
      expect(Validators.phone('+1 000-000 (0001)'), isNull);
      expect(Validators.phone('1234567'), isNull);
    });

    test('rejects empty, too short and non-numeric values', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone(null), isNotNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('abc12345678'), isNotNull);
    });

    test('normalizePhone strips spaces, dashes and brackets', () {
      expect(Validators.normalizePhone('+91 (987) 65-4321'), '+91987654321');
    });
  });

  group('email', () {
    test('accepts a normal address', () => expect(Validators.email('a@b.co'), isNull));

    test('rejects missing parts', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('no-at-sign.com'), isNotNull);
    });
  });

  group('passwords', () {
    test('newPassword needs 8+ characters with a letter and a digit', () {
      expect(Validators.newPassword('abcd1234'), isNull);
      expect(Validators.newPassword('short1'), isNotNull);
      expect(Validators.newPassword('onlyletters'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword(''), isNotNull);
    });

    test('confirmPassword compares with the original', () {
      final check = Validators.confirmPassword(() => 'abcd1234');
      expect(check('abcd1234'), isNull);
      expect(check('different1'), isNotNull);
      expect(check(''), isNotNull);
    });

    test('existingPassword only checks that something was typed', () {
      expect(Validators.existingPassword('x'), isNull);
      expect(Validators.existingPassword(''), isNotNull);
    });
  });

  group('required fields', () {
    test('name is required and limited to 60 characters', () {
      expect(Validators.name('Asha'), isNull);
      expect(Validators.name('   '), isNotNull);
      expect(Validators.name('x' * 61), isNotNull);
    });

    test('emergencyNumber accepts 3-15 digits only', () {
      expect(Validators.emergencyNumber('112'), isNull);
      expect(Validators.emergencyNumber('11'), isNotNull);
      expect(Validators.emergencyNumber('1a2'), isNotNull);
    });
  });
}