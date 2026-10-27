import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/routes/app_routes.dart';
import 'package:sos_safety_system/services/data_repository.dart';
import '../helpers/app_driver.dart';
import '../helpers/fakes.dart';

void main() {
  Future<TestHarness> openSettings(WidgetTester tester) async {
    final harness = await createHarness(signedIn: true);
    await launchApp(tester, harness);
    await goTo(tester, AppRoutes.settings);
    return harness;
  }

  testWidgets('shows the stored profile values', (tester) async {
    await openSettings(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('display_name_field')),
        matching: find.text('Test User'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('emergency_number_field')),
        matching: find.text('112'),
      ),
      findsOneWidget,
    );
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('saves a changed name and emergency number', (tester) async {
    final harness = await openSettings(tester);

    await typeInto(tester, find.byKey(const Key('display_name_field')), 'New Name');
    await typeInto(tester, find.byKey(const Key('emergency_number_field')), '100');
    await tapAndPump(tester, find.byKey(const Key('save_settings_button')), frames: 12);

    final profile = harness.repository.profiles['user-1']!;
    expect(profile.displayName, 'New Name');
    expect(profile.emergencyNumber, '100');
    expect(find.text('Settings saved.'), findsOneWidget);
  });

  testWidgets('invalid values are rejected and nothing is saved', (tester) async {
    final harness = await openSettings(tester);

    await typeInto(tester, find.byKey(const Key('display_name_field')), '');
    await typeInto(tester, find.byKey(const Key('emergency_number_field')), '1a');
    await tapAndPump(tester, find.byKey(const Key('save_settings_button')));

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Use 3-15 digits only'), findsOneWidget);
    expect(harness.repository.profiles['user-1']!.displayName, 'Test User');
    expect(harness.repository.profiles['user-1']!.emergencyNumber, '112');
  });

  testWidgets('turning demo mode off needs confirmation', (tester) async {
    final harness = await openSettings(tester);

    // Cancel path: demo mode stays on.
    await tapAndPump(tester, find.byKey(const Key('demo_mode_switch')));
    expect(find.text('Turn off demo mode?'), findsOneWidget);
    await tapAndPump(tester, find.text('Keep demo mode'));
    await tapAndPump(tester, find.byKey(const Key('save_settings_button')), frames: 12);
    expect(harness.repository.profiles['user-1']!.demoMode, isTrue);

    // Confirm path: demo mode is switched off and saved.
    await tapAndPump(tester, find.byKey(const Key('demo_mode_switch')));
    await tapAndPump(tester, find.byKey(const Key('confirm_live_mode')));
    await tapAndPump(tester, find.byKey(const Key('save_settings_button')), frames: 12);
    expect(harness.repository.profiles['user-1']!.demoMode, isFalse);
  });

  testWidgets('a failed save is reported to the user', (tester) async {
    final harness = await openSettings(tester);
    harness.repository.writeError =
        const RepositoryException('Could not save. Check your connection.');

    await typeInto(tester, find.byKey(const Key('display_name_field')), 'New Name');
    await tapAndPump(tester, find.byKey(const Key('save_settings_button')), frames: 12);

    expect(find.text('Settings saved.'), findsNothing);
    expect(find.textContaining('Could not save'), findsWidgets);
  });

  testWidgets('choosing Dark switches the app theme (Experiment 6)', (tester) async {
    await openSettings(tester);

    await tapAndPump(tester, find.text('Dark'), frames: 4);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}