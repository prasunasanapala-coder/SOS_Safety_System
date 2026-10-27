// ignore_for_file: avoid_print
// Experiment 1(b): a simple Dart program that demonstrates language basics.
// Run with:  dart run tool/dart_basics.dart
//
// It uses the same ideas as the app: variables, null safety, collections,
// functions, classes, enums, async/await and error handling. The helper below
// mirrors the phone validation used in lib/utils/validators.dart.

enum Status { idle, preparing, initiated, cancelled }

class Contact {
  Contact(this.name, this.phone, {this.isPrimary = false});

  final String name;
  final String phone;
  final bool isPrimary;

  @override
  String toString() => '$name ($phone)${isPrimary ? ' [primary]' : ''}';
}

/// Returns an error message or null, like a Flutter form validator.
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'Phone number is required';
  final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
  return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned)
      ? null
      : 'Enter 7-15 digits';
}

Future<int> countdown(int seconds) async {
  var remaining = seconds;
  while (remaining > 0) {
    print('  $remaining...');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    remaining--;
  }
  return remaining;
}

Future<void> main() async {
  // 1. Variables, types and string interpolation
  const appName = 'SOS Safety System';
  var contactCount = 0;
  double version = 1.0;
  print('$appName v$version');

  // 2. Null safety
  String? nickname;
  print('Nickname: ${nickname ?? 'not set'}');

  // 3. Collections (use clearly fake numbers, never real ones)
  final contacts = <Contact>[
    Contact('Test Contact A', '+10000000001', isPrimary: true),
    Contact('Test Contact B', '+10000000002'),
  ];
  contactCount = contacts.length;
  print('Contacts: $contactCount');
  for (final contact in contacts) {
    print(' - $contact');
  }
  final primary = contacts.where((c) => c.isPrimary).toList();
  print('Primary: ${primary.first.name}');

  // 4. Functions and validation
  for (final input in ['+10000000001', '12', '']) {
    print('validatePhone("$input") -> ${validatePhone(input) ?? 'valid'}');
  }

  // 5. Enums and switch expression
  var state = Status.idle;
  String describe(Status s) => switch (s) {
        Status.idle => 'Waiting',
        Status.preparing => 'Countdown running',
        Status.initiated => 'Alert initiated (prototype)',
        Status.cancelled => 'Cancelled',
      };
  print('State: ${describe(state)}');

  // 6. async / await
  state = Status.preparing;
  print('State: ${describe(state)}');
  await countdown(3);
  state = Status.initiated;
  print('State: ${describe(state)}');

  // 7. Exceptions
  try {
    int.parse('not a number');
  } on FormatException catch (e) {
    print('Caught FormatException: ${e.message}');
  }
}