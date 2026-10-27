import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/routes/app_routes.dart';

import 'fakes.dart';

/// Starts the app the way a real launch does: splash -> (1.5 s) -> gate.
/// After this returns, a signed-out harness shows the login screen and a
/// signed-in harness shows the home screen.
Future<void> launchApp(
  WidgetTester tester,
  TestHarness harness, {
  Size size = const Size(800, 1600),
}) async {
  useTallScreen(tester, size: size);
  await tester.pumpWidget(harness.app(initialRoute: AppRoutes.splash));
  await tester.pump(const Duration(milliseconds: 1600)); // splash timer fires
  await pumpFrames(tester, count: 8); // page transition + first data
}

NavigatorState navigatorOf(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

/// Opens a named route on top of the current screen and waits for it.
Future<void> goTo(WidgetTester tester, String route, {Object? arguments}) async {
  navigatorOf(tester).pushNamed(route, arguments: arguments);
  await pumpFrames(tester, count: 8);
}

Future<void> typeInto(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
}

/// Scrolls the target into view, taps it, then lets animations finish.
Future<void> tapAndPump(WidgetTester tester, Finder target, {int frames = 8}) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await pumpFrames(tester, count: frames);
}