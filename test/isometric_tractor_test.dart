import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/painters/isometric_tractor_painter.dart';
import 'package:petani/shared/widgets/isometric_tractor.dart';
import 'package:petani/shared/widgets/task_empty_state.dart';

void main() {
  testWidgets('empty-state canvas fits the art in wide and narrow slivers', (
    tester,
  ) async {
    for (final width in [320.0, 240.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: TaskEmptyState(description: 'No tasks yet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final illustration = tester.getRect(find.byType(IsometricTractor));
      final canvas = tester.getRect(
        find.descendant(
          of: find.byType(IsometricTractor),
          matching: find.byType(CustomPaint),
        ),
      );
      final title = tester.getRect(find.text('Tiada Tugasan'));
      expect(canvas.width, width);
      expect(
        canvas.height,
        closeTo(width / IsometricTractorPainter.aspectRatio, .01),
      );
      expect(canvas.height, lessThan(width * .7));
      expect(canvas.top - illustration.top, IsometricTractor.defaultTopSpacing);
      expect(
        title.top - canvas.bottom,
        closeTo(IsometricTractor.bottomSpacing, .01),
      );
      expect(tester.takeException(), isNull);
    }
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
