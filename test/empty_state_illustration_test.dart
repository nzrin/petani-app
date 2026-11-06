import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/widgets/empty_state_illustration.dart';
import 'package:petani/shared/widgets/isometric_tractor.dart';
import 'package:petani/shared/widgets/task_empty_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'empty-state PNG is bundled at 1000 by 1000 with transparency',
    () async {
      final data = await rootBundle.load(EmptyStateIllustration.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1000);
      expect(frame.image.height, 1000);
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(pixels!.getUint8(3), lessThanOrEqualTo(5));
      frame.image.dispose();
      codec.dispose();
    },
  );

  for (final width in [240.0, 320.0]) {
    testWidgets('static empty state fits $width and settles without a ticker', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              child: const CustomScrollView(
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
      await tester.pumpAndSettle();
      expect(find.byType(IsometricTractor), findsNothing);
      final image = find.descendant(
        of: find.byType(EmptyStateIllustration),
        matching: find.byType(Image),
      );
      expect(image, findsOneWidget);
      expect(tester.getSize(image), Size.square(width));
      final art = tester.getRect(image);
      final title = tester.getRect(find.text('Tiada Tugasan'));
      expect(title.top - art.bottom, EmptyStateIllustration.bottomSpacing);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
