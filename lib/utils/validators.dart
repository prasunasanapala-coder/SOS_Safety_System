/// Form validators (Experiment 7b). Each returns an error message, or null
/// when the value is valid, which is exactly what `TextFormField.validator`
/// expects.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp _digitsOnly = RegExp(r'^[0-9]{3,15}$');

  /// Removes spaces, dashes and brackets so "+91 98765-43210" is accepted.
  static String normalizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-()]'), '');

  static String? required(String? value, {String field = 'This field', int max = 60}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field is required';
    if (text.length > max) return '$field must be at most $max characters';
    return null;
  }

  static String? name(String? value) => required(value, field: 'Name');

  static String? relationship(String? value) =>
      required(value, field: 'Relationship', max: 40);

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Phone number is required';
    if (!_phonePattern.hasMatch(normalizePhone(text))) {
      return 'Enter 7-15 digits, optionally starting with +';
    }
    return null;
  }

  static String? emergencyNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Emergency number is required';
    if (!_digitsOnly.hasMatch(text)) return 'Use 3-15 digits only';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// Registration password rule: at least 8 characters with a letter and a digit.
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'Use at least 8 characters';
    if (!text.contains(RegExp(r'[A-Za-z]')) || !text.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one letter and one digit';
    }
    return null;
  }

  /// Login only checks that something was typed; the server decides validity.
  static String? existingPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Password is required' : null;

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != original()) return 'Passwords do not match';
      return null;
    };
  }
}