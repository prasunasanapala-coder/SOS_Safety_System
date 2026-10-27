import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/routes/app_routes.dart';

import '../helpers/app_driver.dart';
import '../helpers/fakes.dart';

void main() {
  Finder field(int index) => find.byType(TextFormField).at(index);

  testWidgets('a signed-out launch ends on the login screen', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('empty form shows validation messages and does not sign in', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await tapAndPump(tester, find.text('Sign in'));

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('an invalid email address is rejected', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await typeInto(tester, field(0), 'not-an-email');
    await typeInto(tester, field(1), 'abcd1234');
    await tapAndPump(tester, find.text('Sign in'));

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('a wrong password shows the error banner and stays on login', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await typeInto(tester, field(0), 'test@example.com');
    await typeInto(tester, field(1), 'wrongpass');
    await tapAndPump(tester, find.text('Sign in'));

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('valid credentials lead to the home dashboard', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await typeInto(tester, field(0), 'test@example.com');
    await typeInto(tester, field(1), 'abcd1234');
    await tapAndPump(tester, find.text('Sign in'), frames: 12);

    expect(find.textContaining('Hello,'), findsOneWidget);
    expect(find.text('Demo mode is ON'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('the eye icon toggles password visibility (state change)', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tapAndPump(tester, find.byTooltip('Show password'), frames: 2);
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsNothing);
  });

  testWidgets('Forgot password opens another screen and back returns', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await tapAndPump(tester, find.text('Forgot password?'));
    expect(find.text('Welcome back'), findsNothing);

    navigatorOf(tester).pop();
    await pumpFrames(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Create an account opens the register screen', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await tapAndPump(tester, find.text('Create an account'));
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('a private route shows the login screen when signed out (AuthGuard)',
      (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await goTo(tester, AppRoutes.contacts);

    expect(find.text('Emergency contacts'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('an unknown route shows the not-found page with a way back', (tester) async {
    final harness = await createHarness();
    await launchApp(tester, harness);

    await goTo(tester, '/does-not-exist');
    expect(find.text('Page not found'), findsOneWidget);

    await tapAndPump(tester, find.text('Go to start'));
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('signing out from Settings returns to the login screen', (tester) async {
    final harness = await createHarness(signedIn: true);
    await launchApp(tester, harness);
    await goTo(tester, AppRoutes.settings);

    await tapAndPump(tester, find.byKey(const Key('sign_out_button')));
    expect(find.text('Sign out?'), findsOneWidget);

    await tapAndPump(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Sign out'),
      ),
      frames: 12,
    );

    expect(find.text('Welcome back'), findsOneWidget);
  });
}