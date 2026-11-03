import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/widgets/app_toast.dart';

void main() {
  testWidgets('app toast replaces feedback and clears after its lifetime', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => AppToast.show(context, 'Disimpan.'),
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () => AppToast.show(
                    context,
                    'Tidak dapat disimpan.',
                    isError: true,
                  ),
                  child: const Text('Fail'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Disimpan.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

    await tester.tap(find.text('Fail'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Disimpan.'), findsNothing);
    expect(find.text('Tidak dapat disimpan.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tidak dapat disimpan.'), findsNothing);
  });

  testWidgets('toast stays above sheets and keyboard with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);
    var actionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: AppToastHost(child: child!),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Open sheet'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => SizedBox(
                  height: 400,
                  child: Center(
                    child: TextButton(
                      child: const Text('Show toast'),
                      onPressed: () => AppToast.show(
                        sheetContext,
                        'Maklumat projek tidak dapat disimpan. Cuba lagi.',
                        isError: true,
                        actionLabel: 'Cuba lagi',
                        onAction: () => actionCount++,
                        duration: null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show toast'));
    await tester.pumpAndSettle();

    final toast = find.byKey(const ValueKey('app-toast'));
    expect(
      tester.getBottomRight(toast).dy,
      lessThanOrEqualTo(800 - 34 - 65 - 12),
    );
    expect(tester.getSize(toast).width, lessThanOrEqualTo(280));

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(toast).dy, lessThanOrEqualTo(800 - 300 - 12));
    expect(tester.getTopLeft(toast).dy, greaterThan(0));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('app-toast-action')));
    await tester.pumpAndSettle();
    expect(actionCount, 1);
    expect(toast, findsNothing);
  });
}
