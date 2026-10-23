import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dice_deck/main.dart';

void main() {
  testWidgets('drawing decrements the remaining count', (tester) async {
    await tester.pumpWidget(const DiceDeckApp());
    expect(find.text('36 / 36 left'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('35 / 36 left'), findsOneWidget);
    expect(find.byType(CardFace), findsOneWidget);
    expect(find.byType(HistoryEntry), findsOneWidget);
  });

  testWidgets('history survives reshuffles and marks them', (tester) async {
    await tester.pumpWidget(const DiceDeckApp());

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reshuffle'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryEntry), findsOneWidget);
    expect(find.byType(ReshuffleMarker), findsOneWidget);

    // Draw a full deck plus one to trigger the automatic reshuffle.
    for (var i = 0; i < 37; i++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('35 / 36 left'), findsOneWidget);
    // Newest first: latest draw, then the auto-reshuffle marker, then the
    // previous pass. The manual marker is scrolled off-screen.
    final entries = find.byType(HistoryEntry);
    final markerX = tester.getTopLeft(find.byType(ReshuffleMarker)).dx;
    expect(tester.getTopLeft(entries.at(0)).dx, lessThan(markerX));
    expect(tester.getTopLeft(entries.at(1)).dx, greaterThan(markerX));
  });
}
