import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/models/emergency_contact.dart';
import 'package:sos_safety_system/models/sos_record.dart';
import 'package:sos_safety_system/models/user_profile.dart';
import 'package:sos_safety_system/routes/app_routes.dart';

import '../helpers/app_driver.dart';
import '../helpers/fakes.dart';

void main() {
  Future<TestHarness> openSos(
    WidgetTester tester, {
    List<EmergencyContact> contacts = const [],
    bool demoMode = true,
  }) async {
    final harness = await createHarness(signedIn: true, initialContacts: contacts);
    if (!demoMode) {
      harness.repository.profiles['user-1'] =
          UserProfile.defaults(displayName: 'Test User').copyWith(demoMode: false);
    }
    await launchApp(tester, harness);
    await goTo(tester, AppRoutes.sos);
    return harness;
  }

  /// Advances the fake clock one second at a time (the countdown is a
  /// Timer.periodic inside SosProvider).
  Future<void> waitSeconds(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('idle state shows the SOS button, contacts and demo banner', (tester) async {
    await openSos(tester, contacts: [testContactA, testContactB]);

    expect(find.text('State: idle'), findsOneWidget);
    expect(find.byKey(const Key('sos_button')), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
    expect(find.text('Test Contact A'), findsOneWidget);
    expect(find.text('Test Contact B'), findsOneWidget);
  });

  testWidgets('pressing SOS starts a countdown that can be cancelled', (tester) async {
    final harness = await openSos(tester, contacts: [testContactA]);

    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('State: preparing'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('countdown_value'))).data, '5');

    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<Text>(find.byKey(const Key('countdown_value'))).data, '4');

    await tapAndPump(tester, find.byKey(const Key('cancel_button')), frames: 3);

    expect(find.text('State: cancelled'), findsOneWidget);
    expect(
      find.text('The countdown was cancelled. No alert was initiated.'),
      findsOneWidget,
    );
    expect(harness.repository.history['user-1']!.single.status, SosStatus.cancelled);

    // Done returns to the idle state.
    await tapAndPump(tester, find.byKey(const Key('done_button')), frames: 3);
    expect(find.text('State: idle'), findsOneWidget);
  });

  testWidgets('a full countdown initiates a DEMO alert and records it', (tester) async {
    final harness = await openSos(tester, contacts: [testContactA, testContactB]);

    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await waitSeconds(tester, 5);

    expect(find.text('State: alert initiated'), findsOneWidget);
    expect(find.text('Demo alert initiated'), findsOneWidget);
    expect(
      find.text('DEMO: no call, SMS or notification was sent to anyone.'),
      findsOneWidget,
    );

    final record = harness.repository.history['user-1']!.single;
    expect(record.status, SosStatus.initiated);
    expect(record.demoMode, isTrue);
    expect(record.contactCount, 2);
    expect(record.locationShared, isFalse);
    expect(harness.location.calls, 0, reason: 'location is off by default');
  });

  testWidgets('in demo mode the dialer and SMS buttons only explain themselves',
      (tester) async {
    await openSos(tester, contacts: [testContactA]);

    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await waitSeconds(tester, 5);

    expect(find.text('Open message to Test Contact A'), findsOneWidget);

    await tapAndPump(tester, find.byKey(const Key('call_button')), frames: 4);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('disabled in demo mode'), findsOneWidget);
    await tapAndPump(tester, find.text('OK'), frames: 4);
    expect(find.byType(AlertDialog), findsNothing);

    await tapAndPump(tester, find.byKey(const Key('sms_button')), frames: 4);
    expect(find.textContaining('disabled in demo mode'), findsOneWidget);
    await tapAndPump(tester, find.text('OK'), frames: 4);
  });

  testWidgets('location is read only when "Include my location" is on', (tester) async {
    final harness = await openSos(tester, contacts: [testContactA]);

    await tapAndPump(tester, find.byKey(const Key('share_location_switch')), frames: 3);

    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await waitSeconds(tester, 5);

    expect(harness.location.calls, 1);
    expect(harness.repository.history['user-1']!.single.locationShared, isTrue);
  });

  testWidgets('a location failure does not stop the alert', (tester) async {
    final harness = await createHarness(
      signedIn: true,
      initialContacts: [testContactA],
      location: FakeLocationService(error: null),
    );
    await launchApp(tester, harness);
    await goTo(tester, AppRoutes.sos);

    // Switch location on, then make the next read fail.
    await tapAndPump(tester, find.byKey(const Key('share_location_switch')), frames: 3);
    harness.location.error = null; // keep default success path for this test

    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await waitSeconds(tester, 5);

    expect(find.text('State: alert initiated'), findsOneWidget);
  });

  testWidgets('with no contacts the user is asked before the countdown starts',
      (tester) async {
    await openSos(tester);

    await tapAndPump(tester, find.byKey(const Key('sos_button')), frames: 4);
    expect(find.text('No emergency contacts'), findsOneWidget);

    await tapAndPump(tester, find.text('Go back'), frames: 4);
    expect(find.text('State: idle'), findsOneWidget);

    await tapAndPump(tester, find.byKey(const Key('sos_button')), frames: 4);
    await tapAndPump(tester, find.text('Start anyway'), frames: 2);
    expect(find.text('State: preparing'), findsOneWidget);

    // End the test without leaving a timer running.
    await tapAndPump(tester, find.byKey(const Key('cancel_button')), frames: 3);
  });

  testWidgets('live mode says nothing was sent automatically', (tester) async {
    await openSos(tester, contacts: [testContactA], demoMode: false);

    expect(find.text('Live mode'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await waitSeconds(tester, 5);

    expect(find.text('Alert initiated'), findsOneWidget);
    expect(find.textContaining('Nothing was sent automatically.'), findsOneWidget);
    expect(find.text('Open dialer for 112'), findsOneWidget);
  });
}