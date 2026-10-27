import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/widgets/state_views.dart';
import 'package:sos_safety_system/widgets/status_banner.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('LoadingView shows a spinner and its label', (tester) async {
    await tester.pumpWidget(host(const LoadingView(label: 'Loading tips...')));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading tips...'), findsOneWidget);
  });

  testWidgets('EmptyState shows its text and runs the action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(host(EmptyState(
      icon: Icons.contacts_outlined,
      title: 'No emergency contacts',
      message: 'Add the people you trust.',
      actionLabel: 'Add contact',
      onAction: () => pressed = true,
    )));

    expect(find.text('No emergency contacts'), findsOneWidget);
    expect(find.text('Add the people you trust.'), findsOneWidget);

    await tester.tap(find.text('Add contact'));
    await tester.pump();
    expect(pressed, isTrue);
  });

  testWidgets('EmptyState without an action shows no button', (tester) async {
    await tester.pumpWidget(host(const EmptyState(
      icon: Icons.history,
      title: 'No SOS events yet',
      message: 'Nothing recorded.',
    )));

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('ErrorView shows the message and retry works', (tester) async {
    var retries = 0;
    await tester.pumpWidget(host(ErrorView(
      message: 'Could not reach the tips server.',
      onRetry: () => retries++,
    )));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Could not reach the tips server.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('StatusBanner shows title and message', (tester) async {
    await tester.pumpWidget(host(const StatusBanner(
      kind: BannerKind.warning,
      title: 'Demo mode is ON',
      message: 'Nothing is sent to anyone.',
    )));

    expect(find.text('Demo mode is ON'), findsOneWidget);
    expect(find.text('Nothing is sent to anyone.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });
}