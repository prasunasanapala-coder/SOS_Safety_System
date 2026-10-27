import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/models/safety_tip.dart';
import 'package:sos_safety_system/widgets/tip_card.dart';

void main() {
  const tip = SafetyTip(
    id: 'p1',
    category: 'Personal safety',
    title: 'Share your plans',
    body: 'Tell a trusted person where you are going.',
  );

  testWidgets('shows the tip and toggles the favourite icon (state change)', (tester) async {
    var favorite = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => TipCard(
            tip: tip,
            isFavorite: favorite,
            onToggleFavorite: () => setState(() => favorite = !favorite),
          ),
        ),
      ),
    ));

    expect(find.text('Share your plans'), findsOneWidget);
    expect(find.text('Personal safety'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });
}