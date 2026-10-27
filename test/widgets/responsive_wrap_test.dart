import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/widgets/responsive_layout.dart';

import '../helpers/fakes.dart';

void main() {
  Future<void> pumpWrap(WidgetTester tester, double width) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ResponsiveWrap(
              minItemWidth: 200,
              spacing: 10,
              children: [
                for (var i = 0; i < 4; i++) SizedBox(key: Key('item$i'), height: 40),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('wide layout puts all four items in one row', (tester) async {
    useTallScreen(tester, size: const Size(1200, 800));
    await pumpWrap(tester, 900);

    final firstY = tester.getTopLeft(find.byKey(const Key('item0'))).dy;
    final lastY = tester.getTopLeft(find.byKey(const Key('item3'))).dy;
    expect(lastY, firstY);
  });

  testWidgets('medium layout uses two columns', (tester) async {
    useTallScreen(tester, size: const Size(1200, 800));
    await pumpWrap(tester, 450);

    final y0 = tester.getTopLeft(find.byKey(const Key('item0'))).dy;
    final y1 = tester.getTopLeft(find.byKey(const Key('item1'))).dy;
    final y2 = tester.getTopLeft(find.byKey(const Key('item2'))).dy;
    expect(y1, y0);
    expect(y2, greaterThan(y0));
  });

  testWidgets('narrow layout stacks items in one column', (tester) async {
    useTallScreen(tester, size: const Size(1200, 800));
    await pumpWrap(tester, 300);

    final y0 = tester.getTopLeft(find.byKey(const Key('item0'))).dy;
    final y1 = tester.getTopLeft(find.byKey(const Key('item1'))).dy;
    expect(y1, greaterThan(y0));
  });
}