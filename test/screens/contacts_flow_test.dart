import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/models/emergency_contact.dart';
import 'package:sos_safety_system/routes/app_routes.dart';
import 'package:sos_safety_system/utils/validators.dart';
import 'package:sos_safety_system/widgets/contact_card.dart';

import '../helpers/app_driver.dart';
import '../helpers/fakes.dart';

void main() {
  Finder menuButton(int index) =>
      find.byType(PopupMenuButton<ContactAction>).at(index);

  Future<TestHarness> openContacts(
    WidgetTester tester, {
    List<EmergencyContact> contacts = const [],
  }) async {
    final harness = await createHarness(signedIn: true, initialContacts: contacts);
    await launchApp(tester, harness);
    await goTo(tester, AppRoutes.contacts);
    return harness;
  }

  Future<void> fillForm(
    WidgetTester tester, {
    required String name,
    required String phone,
    required String relationship,
  }) async {
    await typeInto(tester, find.byKey(const Key('name_field')), name);
    await typeInto(tester, find.byKey(const Key('phone_field')), phone);
    await typeInto(tester, find.byKey(const Key('relationship_field')), relationship);
  }

  Future<void> saveForm(WidgetTester tester) =>
      tapAndPump(tester, find.byKey(const Key('save_contact_button')), frames: 12);

  testWidgets('shows the empty state when there are no contacts', (tester) async {
    await openContacts(tester);

    expect(find.text('No emergency contacts'), findsOneWidget);
    expect(find.byKey(const Key('add_contact_fab')), findsOneWidget);
  });

  testWidgets('adds the first contact, which automatically becomes primary', (tester) async {
    final harness = await openContacts(tester);

    await tapAndPump(tester, find.byKey(const Key('add_contact_fab')));
    await fillForm(
      tester,
      name: 'Test Contact A',
      phone: '+10000000001',
      relationship: 'Friend',
    );
    await saveForm(tester);

    final saved = harness.repository.contacts['user-1']!;
    expect(saved.length, 1);
    expect(saved.single.name, 'Test Contact A');
    expect(saved.single.phone, '+10000000001');
    expect(saved.single.isPrimary, isTrue);

    expect(find.text('Test Contact A'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Contact added.'), findsOneWidget);
  });

  testWidgets('an empty form shows every validation message and saves nothing',
      (tester) async {
    final harness = await openContacts(tester);

    await tapAndPump(tester, find.byKey(const Key('add_contact_fab')));
    await saveForm(tester);

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);
    expect(find.text('Relationship is required'), findsOneWidget);
    expect(harness.repository.contacts['user-1'] ?? [], isEmpty);
  });

  testWidgets('an invalid phone number is rejected', (tester) async {
    final harness = await openContacts(tester);

    await tapAndPump(tester, find.byKey(const Key('add_contact_fab')));
    await fillForm(tester, name: 'Test Contact A', phone: '12', relationship: 'Friend');
    await saveForm(tester);

    expect(find.text(Validators.phone('12')!), findsOneWidget);
    expect(harness.repository.contacts['user-1'] ?? [], isEmpty);
  });

  testWidgets('a relationship chip fills the relationship field', (tester) async {
    await openContacts(tester);

    await tapAndPump(tester, find.byKey(const Key('add_contact_fab')));
    await tapAndPump(tester, find.widgetWithText(ActionChip, 'Friend'), frames: 2);

    expect(
      find.descendant(
        of: find.byKey(const Key('relationship_field')),
        matching: find.text('Friend'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('marking a new contact primary demotes the old one', (tester) async {
    final harness = await openContacts(tester, contacts: [testContactA]);

    await tapAndPump(tester, find.byKey(const Key('add_contact_fab')));
    await fillForm(
      tester,
      name: 'Test Contact C',
      phone: '+10000000003',
      relationship: 'Parent',
    );
    await tapAndPump(tester, find.byKey(const Key('primary_switch')), frames: 2);
    await saveForm(tester);

    final saved = harness.repository.contacts['user-1']!;
    expect(saved.length, 2);
    final primaries = saved.where((c) => c.isPrimary).toList();
    expect(primaries.length, 1);
    expect(primaries.single.name, 'Test Contact C');
  });

  testWidgets('lists existing contacts and marks the primary one', (tester) async {
    await openContacts(tester, contacts: [testContactA, testContactB]);

    expect(find.text('Test Contact A'), findsOneWidget);
    expect(find.text('Test Contact B'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
  });

  testWidgets('Make primary moves the primary marker to another contact', (tester) async {
    final harness = await openContacts(tester, contacts: [testContactA, testContactB]);

    await tapAndPump(tester, menuButton(1)); // second card = Test Contact B
    await tapAndPump(tester, find.text('Make primary'));

    final saved = harness.repository.contacts['user-1']!;
    expect(saved.firstWhere((c) => c.id == 'b1').isPrimary, isTrue);
    expect(saved.firstWhere((c) => c.id == 'a1').isPrimary, isFalse);
    expect(find.text('Test Contact B is now your primary contact.'), findsOneWidget);
  });

  testWidgets('Edit pre-fills the form and saves the change', (tester) async {
    final harness = await openContacts(tester, contacts: [testContactA]);

    await tapAndPump(tester, menuButton(0));
    await tapAndPump(tester, find.text('Edit'));

    expect(find.text('Edit contact'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('name_field')),
        matching: find.text('Test Contact A'),
      ),
      findsOneWidget,
    );

    await typeInto(tester, find.byKey(const Key('name_field')), 'Test Contact A2');
    await saveForm(tester);

    final saved = harness.repository.contacts['user-1']!;
    expect(saved.single.name, 'Test Contact A2');
    expect(saved.single.isPrimary, isTrue);
    expect(find.text('Contact updated.'), findsOneWidget);
  });

  testWidgets('Delete asks for confirmation before removing a contact', (tester) async {
    final harness = await openContacts(tester, contacts: [testContactA, testContactB]);

    await tapAndPump(tester, menuButton(1));
    await tapAndPump(tester, find.text('Delete'));
    expect(find.text('Delete contact?'), findsOneWidget);

    // Cancel first: nothing is removed.
    await tapAndPump(tester, find.text('Cancel'));
    expect(harness.repository.contacts['user-1']!.length, 2);

    // Then confirm.
    await tapAndPump(tester, menuButton(1));
    await tapAndPump(tester, find.text('Delete'));
    await tapAndPump(tester, find.byKey(const Key('confirm_delete')));

    final saved = harness.repository.contacts['user-1']!;
    expect(saved.map((c) => c.name), ['Test Contact A']);
    expect(find.text('Test Contact B'), findsNothing);
    expect(find.text('Contact deleted.'), findsOneWidget);
  });

  testWidgets('deleting the primary contact promotes another one', (tester) async {
    final harness = await openContacts(tester, contacts: [testContactA, testContactB]);

    await tapAndPump(tester, menuButton(0)); // Test Contact A is primary
    await tapAndPump(tester, find.text('Delete'));
    await tapAndPump(tester, find.byKey(const Key('confirm_delete')), frames: 12);

    final saved = harness.repository.contacts['user-1']!;
    expect(saved.single.name, 'Test Contact B');
    expect(saved.single.isPrimary, isTrue);
  });

  testWidgets('a load error shows the error view', (tester) async {
    final harness = await createHarness(signedIn: true);
    harness.repository.streamError = Exception('permission-denied');
    await launchApp(tester, harness);
    await goTo(tester, AppRoutes.contacts);

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(
      find.text('Could not load contacts. Check your connection and sign-in.'),
      findsOneWidget,
    );
  });
}