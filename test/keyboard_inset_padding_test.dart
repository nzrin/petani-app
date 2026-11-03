import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

void main() {
  testWidgets('sheet follows keyboard inset in the same frame', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    var descendantInset = -1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: KeyboardInsetPadding(
              child: Builder(
                builder: (context) {
                  descendantInset = MediaQuery.viewInsetsOf(context).bottom;
                  return const SizedBox(
                    key: Key('keyboard-inset-test-surface'),
                    width: 120,
                    height: 100,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final initialBottom = tester
        .getRect(find.byKey(const Key('keyboard-inset-test-surface')))
        .bottom;
    expect(descendantInset, 0);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    final keyboardBottom = tester
        .getRect(find.byKey(const Key('keyboard-inset-test-surface')))
        .bottom;
    expect(keyboardBottom, initialBottom - 300);
    expect(descendantInset, 0);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();

    expect(
      tester
          .getRect(find.byKey(const Key('keyboard-inset-test-surface')))
          .bottom,
      initialBottom,
    );
  });
}
