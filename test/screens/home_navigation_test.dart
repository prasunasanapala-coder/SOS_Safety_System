import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/screens/contacts_screen.dart';
import 'package:sos_safety_system/screens/settings_screen.dart';
import 'package:sos_safety_system/screens/sos_screen.dart';
import 'package:sos_safety_system/screens/tips_screen.dart';
import 'package:sos_safety_system/widgets/feature_tile.dart';

import '../helpers/app_driver.dart';
import '../helpers/fakes.dart';

void main() {
  group('home dashboard', () {
    testWidgets('greets the user and shows demo mode', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness);

      expect(find.text('Hello, Test User'), findsOneWidget);
      expect(find.text('Demo mode is ON'), findsOneWidget);
    });

    testWidgets('warns when there are no emergency contacts', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness);

      expect(find.text('No emergency contacts yet'), findsOneWidget);
    });

    testWidgets('shows how many contacts are ready', (tester) async {
      final harness = await createHarness(
        signedIn: true,
        initialContacts: [testContactA, testContactB],
      );
      await launchApp(tester, harness);

      expect(find.text('2 emergency contacts ready.'), findsOneWidget);
    });

    testWidgets('uses the singular form for one contact', (tester) async {
      final harness = await createHarness(signedIn: true, initialContacts: [testContactA]);
      await launchApp(tester, harness);

      expect(find.text('1 emergency contact ready.'), findsOneWidget);
    });
  });

  group('navigation with named routes', () {
    testWidgets('the SOS button opens the SOS screen', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness);

      await tapAndPump(tester, find.byKey(const Key('sos_button')));

      expect(find.byType(SosScreen), findsOneWidget);
      expect(find.text('SOS alert'), findsOneWidget);
    });

    testWidgets('the Contacts tile opens contacts and Back returns home', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness);

      await tapAndPump(tester, find.text('Contacts'));
      expect(find.byType(ContactsScreen), findsOneWidget);

      await tester.pageBack();
      await pumpFrames(tester);
      expect(find.byType(ContactsScreen), findsNothing);
      expect(find.textContaining('Hello,'), findsOneWidget);
    });

    testWidgets('the Safety tips tile opens the tips screen', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness);

      await tapAndPump(tester, find.text('Safety tips'));
      expect(find.byType(TipsScreen), findsOneWidget);
    });

    testWidgets('the settings icon opens Settings', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness);

      await tapAndPump(tester, find.byTooltip('Settings'));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('responsive layout (Experiment 3)', () {
    testWidgets('desktop width places feature tiles side by side', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness, size: const Size(1200, 1000));

      final first = tester.getTopLeft(find.widgetWithText(FeatureTile, 'Contacts')).dy;
      final third = tester.getTopLeft(find.widgetWithText(FeatureTile, 'Safety tips')).dy;
      expect(third, first, reason: 'first and third tile share a row on desktop');
    });

    testWidgets('phone width wraps feature tiles onto more rows', (tester) async {
      final harness = await createHarness(signedIn: true);
      await launchApp(tester, harness, size: const Size(400, 1600));

      final first = tester.getTopLeft(find.widgetWithText(FeatureTile, 'Contacts')).dy;
      final third = tester.getTopLeft(find.widgetWithText(FeatureTile, 'Safety tips')).dy;
      expect(third, greaterThan(first));
    });

    testWidgets('SOS screen is two columns on desktop', (tester) async {
      final harness = await createHarness(signedIn: true, initialContacts: [testContactA]);
      await launchApp(tester, harness, size: const Size(1200, 1000));
      await goTo(tester, '/sos');

      final button = tester.getCenter(find.byKey(const Key('sos_button')));
      final info = tester.getCenter(find.text('Contacts to alert'));
      expect(info.dx, greaterThan(button.dx));
    });

    testWidgets('SOS screen is one column on a phone', (tester) async {
      final harness = await createHarness(signedIn: true, initialContacts: [testContactA]);
      await launchApp(tester, harness, size: const Size(400, 1600));
      await goTo(tester, '/sos');

      final buttonBottom = tester.getBottomLeft(find.byKey(const Key('sos_button'))).dy;
      final infoTop = tester.getTopLeft(find.text('Contacts to alert')).dy;
      expect(infoTop, greaterThan(buttonBottom));
    });
  });
}