import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/routes/app_routes.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('first launch shows the onboarding screen', (tester) async {
    useTallScreen(tester);
    final harness = await createHarness(onboardingSeen: false);

    await tester.pumpWidget(harness.app(initialRoute: AppRoutes.splash));
    await pumpFrames(tester, count: 6);

    expect(find.text('SOS Safety System'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('Demo mode is on by default'), findsOneWidget);
  });

  testWidgets('Get started leads to the login screen when signed out', (tester) async {
    useTallScreen(tester);
    final harness = await createHarness(onboardingSeen: false);

    await tester.pumpWidget(harness.app(initialRoute: AppRoutes.splash));
    await pumpFrames(tester, count: 6);

    await tester.tap(find.text('Get started'));
    await pumpFrames(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}