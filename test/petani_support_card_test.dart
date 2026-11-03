import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/views/petani_support_card.dart';

void main() {
  testWidgets('donation list follows the requested order and opens QR sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PetaniSupportCard(
              initiallyHidden: false,
              onHiddenChanged: (_) async {},
            ),
          ),
        ),
      ),
    );

    for (final id in [
      'wise',
      'paypal',
      'touch-n-go',
      'ocbc',
      'bank-islam',
      'maybank',
      'buy-me-a-coffee',
    ]) {
      expect(
        find.byKey(ValueKey<String>('support-detail-$id')),
        findsOneWidget,
      );
    }

    final ocbcQrButton = find.byTooltip('Paparkan kod QR OCBC');
    await tester.ensureVisible(ocbcQrButton);
    await tester.pumpAndSettle();
    await tester.tap(ocbcQrButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('donation-qr-sheet')),
      findsOneWidget,
    );
    final qrSheet = find.byKey(const ValueKey<String>('donation-qr-sheet'));
    expect(find.text('Kod QR OCBC'), findsOneWidget);
    expect(
      find.descendant(of: qrSheet, matching: find.text('1552037859')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('donation-qr-OCBC')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('save-donation-qr')),
      findsOneWidget,
    );
    expect(find.text('Simpan ke Galeri'), findsOneWidget);
  });
}
