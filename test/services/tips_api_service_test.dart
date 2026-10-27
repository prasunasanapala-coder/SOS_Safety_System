import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/services/tips_api_service.dart';

import '../helpers/fakes.dart';

void main() {
  test('returns parsed tips on a 200 response', () async {
    final tips = await fakeTipsApi().fetchTips();
    expect(tips.length, 2);
    expect(tips.first.title, 'Share your plans');
  });

  test('returns an empty list when the server sends no tips', () async {
    final tips = await fakeTipsApi(body: {'tips': <Object>[]}).fetchTips();
    expect(tips, isEmpty);
  });

  test('skips malformed items but keeps valid ones', () async {
    final tips = await fakeTipsApi(body: {
      'tips': [
        {'id': 'broken'},
        {'id': 'ok', 'category': 'Travel safety', 'title': 'T', 'body': 'B'},
      ],
    }).fetchTips();
    expect(tips.length, 1);
    expect(tips.single.id, 'ok');
  });

  test('throws TipsApiException on a server error', () async {
    await expectLater(
      fakeTipsApi(status: 500, body: {'error': 'boom'}).fetchTips(),
      throwsA(isA<TipsApiException>()),
    );
  });

  test('throws TipsApiException when the network is unreachable', () async {
    await expectLater(
      fakeTipsApi(throwNetworkError: true).fetchTips(),
      throwsA(isA<TipsApiException>().having(
        (e) => e.message,
        'message',
        contains('Could not reach'),
      )),
    );
  });

  test('throws TipsApiException for invalid JSON', () async {
    await expectLater(
      fakeTipsApi(body: 'this is not json').fetchTips(),
      throwsA(isA<TipsApiException>()),
    );
  });

  test('throws TipsApiException for an unexpected JSON shape', () async {
    await expectLater(
      fakeTipsApi(body: {'unexpected': true}).fetchTips(),
      throwsA(isA<TipsApiException>()),
    );
  });
}