import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/widgets/sos_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('shows the SOS label and calls onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(SosButton(onPressed: () => taps++)));

    expect(find.text('SOS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sos_button')));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('does nothing when disabled', (tester) async {
    await tester.pumpWidget(host(const SosButton(onPressed: null)));

    await tester.tap(find.byKey(const Key('sos_button')), warnIfMissed: false);
    await tester.pump();

    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('keeps animating without errors (pulse)', (tester) async {
    await tester.pumpWidget(host(SosButton(onPressed: () {})));

    // The pulse is a repeating animation, so pump fixed durations instead of
    // pumpAndSettle (which would wait forever).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes an accessible label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(SosButton(onPressed: () {})));

    expect(find.bySemanticsLabel('Start SOS alert countdown'), findsOneWidget);
    handle.dispose();
  });
}