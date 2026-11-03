import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/auth/views/main_auth_view.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/views/profile_login_card.dart';
import 'package:petani/profile/views/profile_view.dart';

void main() {
  testWidgets(
    'compact login card puts the green explanation pill at the top right',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(_app());
      await tester.pump();

      final card = find.byKey(const Key('profile-login-card'));
      final title = find.byKey(const Key('profile-login-title'));
      final why = find.byKey(const Key('profile-why-login-button'));
      final login = find.byKey(const Key('profile-login-button'));
      expect(tester.widget<Text>(title).data, 'DATA SELAMAT');
      expect(
        find.descendant(of: card, matching: find.byType(Image)),
        findsNothing,
      );
      expect(find.textContaining('Tanpa log masuk'), findsNothing);
      expect(find.text('Log Masuk ke akaun anda'), findsNothing);
      expect(find.text('Kenapa mesti Log Masuk'), findsNothing);
      expect(find.text('Kenapa?'), findsOneWidget);
      final pillStyle = tester.widget<TextButton>(why).style!;
      expect(pillStyle.backgroundColor?.resolve({}), AppColors.mint);
      expect(pillStyle.foregroundColor?.resolve({}), AppColors.forest);
      expect(pillStyle.shape?.resolve({}), isA<StadiumBorder>());
      expect(tester.getSize(card).height, lessThan(170));
      expect(
        tester.getTopLeft(why).dx,
        greaterThan(tester.getTopRight(title).dx),
      );
      expect(tester.getCenter(why).dy, closeTo(tester.getCenter(title).dy, 1));
      expect(
        tester.getTopLeft(login).dy,
        greaterThan(tester.getBottomLeft(why).dy),
      );
      expect(
        tester.getTopRight(why).dx,
        closeTo(tester.getTopRight(card).dx - 16, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('why login opens the image and details in a dismissible sheet', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile-why-login-button')));
    await _finishTransition(tester);

    final sheet = find.byKey(const Key('app-confirmation-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.text('Kenapa mesti Log Masuk'), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const Key('app-confirmation-sheet-image')),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/farmer_phone.png',
    );
    expect(find.textContaining('Tanpa log masuk'), findsOneWidget);
    expect(find.textContaining('Gunakan akaun yang sama'), findsOneWidget);
    expect(
      find.textContaining('memerlukan sambungan internet'),
      findsOneWidget,
    );
    expect(
      find.textContaining('masih boleh menggunakan Petani tanpa log masuk'),
      findsOneWidget,
    );
    expect(find.byType(MainAuthView), findsNothing);

    final dismiss = find.byKey(
      const Key('app-confirmation-sheet-confirm-button'),
    );
    await tester.ensureVisible(dismiss);
    await _finishTransition(tester);
    await tester.tap(dismiss);
    await _finishTransition(tester);
    expect(sheet, findsNothing);
    expect(find.byType(MainAuthView), findsNothing);

    // Reading the explanation is optional; the original login action remains.
    await tester.tap(find.byKey(const Key('profile-login-button')));
    await _finishTransition(tester);
    expect(find.byType(MainAuthView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'login button opens authentication without first opening the sheet',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.byKey(const Key('profile-login-button')));
      await tester.pumpAndSettle();
      expect(find.byType(MainAuthView), findsOneWidget);
      expect(find.byKey(const Key('app-confirmation-sheet')), findsNothing);
    },
  );

  for (final layout in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
    (size: const Size(844, 390), scale: 1.0),
    (size: const Size(1024, 768), scale: 1.0),
  ]) {
    testWidgets(
      'login card and information sheet fit ${layout.size} at ${layout.scale}x text',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(layout.size);
        await tester.pumpWidget(
          _app(textScale: layout.scale, isolateCard: true),
        );
        await tester.pump();
        final why = find.byKey(const Key('profile-why-login-button'));
        await tester.ensureVisible(why);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(why);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('app-confirmation-sheet')), findsOneWidget);
        expect(tester.takeException(), isNull);

        final dismiss = find.byKey(
          const Key('app-confirmation-sheet-confirm-button'),
        );
        await tester.ensureVisible(dismiss);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(dismiss);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('app-confirmation-sheet')), findsNothing);
      },
    );
  }
}

Future<void> _finishTransition(WidgetTester tester) async {
  // The optional support section has a continuously pulsing indicator.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Widget _app({double textScale = 1, bool isolateCard = false}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: isolateCard
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ProfileLoginCard(onLogin: () {}),
          )
        : const ProfileView(),
  ),
);
