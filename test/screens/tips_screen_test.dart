import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sos_safety_system/routes/app_routes.dart';
import 'package:sos_safety_system/services/tips_api_service.dart';

import '../helpers/app_driver.dart';
import '../helpers/fakes.dart';

void main() {
  Future<TestHarness> openTips(WidgetTester tester, TipsApiService api) async {
    final harness = await createHarness(signedIn: true, tipsApi: api);
    await launchApp(tester, harness);
    await goTo(tester, AppRoutes.tips);
    return harness;
  }

  testWidgets('shows a loading indicator until the API answers, then the tips',
      (tester) async {
    final gate = Completer<void>();
    final api = TipsApiService(
      baseUrl: 'http://test.local/tips.json',
      client: MockClient((request) async {
        await gate.future;
        return http.Response(
          jsonEncode(sampleTipsJson),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await openTips(tester, api);
    expect(find.text('Loading tips...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    gate.complete();
    await pumpFrames(tester);

    expect(find.text('Loading tips...'), findsNothing);
    expect(find.text('Share your plans'), findsOneWidget);
    expect(find.text('Use licensed transport'), findsOneWidget);
  });

  testWidgets('shows category chips and filters tips by category', (tester) async {
    await openTips(tester, fakeTipsApi());

    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Personal safety'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Travel safety'), findsOneWidget);

    await tapAndPump(tester, find.widgetWithText(ChoiceChip, 'Travel safety'), frames: 3);
    expect(find.text('Use licensed transport'), findsOneWidget);
    expect(find.text('Share your plans'), findsNothing);

    await tapAndPump(tester, find.widgetWithText(ChoiceChip, 'All'), frames: 3);
    expect(find.text('Share your plans'), findsOneWidget);
  });

  testWidgets('favouriting a tip and filtering by favourites works', (tester) async {
    await openTips(tester, fakeTipsApi());

    // No favourites yet: the filter shows an explanatory message.
    await tapAndPump(tester, find.byKey(const Key('favorites_filter')), frames: 3);
    expect(find.text('No tips match this filter.'), findsOneWidget);
    await tapAndPump(tester, find.byKey(const Key('favorites_filter')), frames: 3);

    // Favourite the first tip, then filter.
    await tapAndPump(tester, find.byIcon(Icons.favorite_border).first, frames: 3);
    await tapAndPump(tester, find.byKey(const Key('favorites_filter')), frames: 3);

    expect(find.text('Share your plans'), findsOneWidget);
    expect(find.text('Use licensed transport'), findsNothing);
  });

  testWidgets('shows the empty state when the API returns no tips', (tester) async {
    await openTips(tester, fakeTipsApi(body: {'tips': <Object>[]}));

    expect(find.text('No tips available'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
  });

  testWidgets('shows an error with a retry button when the network fails', (tester) async {
    await openTips(tester, fakeTipsApi(throwNetworkError: true));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('Could not reach'), findsOneWidget);

    // Retrying calls the API again (it fails again with the same fake).
    await tapAndPump(tester, find.text('Try again'));
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('shows an error when the server answers 500', (tester) async {
    await openTips(tester, fakeTipsApi(status: 500, body: {'error': 'boom'}));

    expect(find.text('Something went wrong'), findsOneWidget);
  });
}