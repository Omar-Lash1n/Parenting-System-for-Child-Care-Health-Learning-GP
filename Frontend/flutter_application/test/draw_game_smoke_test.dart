// Runtime smoke test for the draw game's shape-validation path.
// It does NOT assert pixel-perfect recognition (that depends on real fonts);
// it verifies the page builds, drawing works, and the async glyph-rasterization
// validation runs without throwing — and that a clearly-wrong scribble does
// NOT trigger the success celebration.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Ajial/child-app/home/draw_game_page.dart';

void main() {
  testWidgets('wrong scribble does not show the win dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DrawGamePage()));
    // Continuous pulse animation never "settles" — pump fixed frames instead.
    await tester.pump(const Duration(milliseconds: 700));

    // Draw a tiny scribble in the top-left corner (nowhere near the centered
    // guide letter) — this must be rejected, not celebrated.
    final canvas = find.byType(CustomPaint);
    expect(canvas, findsWidgets);

    await tester.dragFrom(const Offset(30, 200), const Offset(20, 20));
    await tester.pump();

    // Tap "تم" and let the async validation finish.
    await tester.tap(find.text('تم! 🎉'));
    await tester.pump(); // start async validation
    await tester.pump(const Duration(milliseconds: 600)); // let it complete

    // No success celebration; instead the gentle retry banner appears.
    expect(find.text('أحسنت! 🎉'), findsNothing);
    expect(find.text('جرّب مرة أخرى ✏️'), findsOneWidget);

    // Drain the banner's auto-hide timer so the test ends cleanly.
    await tester.pump(const Duration(milliseconds: 2000));
  });

  testWidgets('sentence level validates without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DrawGamePage()));
    await tester.pump(const Duration(milliseconds: 700));

    // Switch to the hardest level (multi-line, smallest font, wrapped text).
    await tester.tap(find.text('جمل'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('ارسم الجمل'), findsOneWidget);

    // A wrong scribble must still be rejected (exercises the multi-line
    // rasterization + grid validation path without exceptions).
    await tester.dragFrom(const Offset(30, 60), const Offset(15, 15));
    await tester.pump();
    await tester.tap(find.text('تم! 🎉'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('أحسنت! 🎉'), findsNothing);
    expect(find.text('جرّب مرة أخرى ✏️'), findsOneWidget);

    // Drain the banner's auto-hide timer so the test ends cleanly.
    await tester.pump(const Duration(milliseconds: 2000));
  });
}
