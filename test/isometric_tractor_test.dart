import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/painters/isometric_tractor_painter.dart';
import 'package:petani/shared/widgets/isometric_tractor.dart';

void main() {
  ValueListenable<double> clock(WidgetTester tester) =>
      (tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(IsometricTractor),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as IsometricTractorPainter)
          .animation!;

  testWidgets('tractor limits paints on high refresh rate displays', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: IsometricTractor()));
    final animation = clock(tester);
    var updates = 0;
    void onFrame() => updates++;
    animation.addListener(onFrame);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(microseconds: 8334));
    }
    expect(updates, inInclusiveRange(29, 31));
    expect(animation.value, closeTo(1, .04));
    animation.removeListener(onFrame);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tractor pauses behind sheets and keyboards then resumes', (
    tester,
  ) async {
    late BuildContext routeContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            routeContext = context;
            return const Scaffold(body: IsometricTractor());
          },
        ),
      ),
    );
    final animation = clock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    showModalBottomSheet<void>(
      context: routeContext,
      builder: (_) => const SizedBox(height: 150),
    );
    await tester.pumpAndSettle();
    final paused = animation.value;
    await tester.pump(const Duration(seconds: 2));
    expect(animation.value, paused);
    Navigator.of(routeContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(animation.value, greaterThan(paused));

    addTearDown(tester.view.resetViewInsets);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    final keyboardPaused = animation.value;
    await tester.pump(const Duration(seconds: 1));
    expect(animation.value, keyboardPaused);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(animation.value, greaterThan(keyboardPaused));
    await tester.pumpWidget(const SizedBox.shrink());
    // Drain the frame that was already scheduled before the ticker disposed.
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tractor runs in place and pauses when hidden or motion is reduced',
    (tester) async {
      Future<void> show({bool enabled = true, bool reduceMotion = false}) =>
          tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduceMotion),
                child: TickerMode(
                  enabled: enabled,
                  child: const Center(child: IsometricTractor()),
                ),
              ),
            ),
          );
      double elapsed() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(IsometricTractor),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter!
                  as IsometricTractorPainter)
              .animation!
              .value;

      await show();
      final position = tester.getRect(find.byType(IsometricTractor));
      await tester.pump(const Duration(milliseconds: 500));
      expect(elapsed(), greaterThan(0));
      expect(tester.getRect(find.byType(IsometricTractor)), position);

      await show(enabled: false);
      final paused = elapsed();
      await tester.pump(const Duration(seconds: 2));
      expect(elapsed(), paused);

      await show();
      await tester.pump(const Duration(milliseconds: 100));
      expect(elapsed(), greaterThan(paused));
      expect(elapsed(), lessThan(paused + .2));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final background = elapsed();
      await tester.pump(const Duration(seconds: 1));
      expect(elapsed(), background);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(elapsed(), greaterThan(background));

      await show(reduceMotion: true);
      final reduced = elapsed();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(elapsed(), reduced);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
