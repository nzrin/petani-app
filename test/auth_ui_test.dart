import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/auth/models/app_auth_user.dart';
import 'package:petani/auth/models/email_login_data.dart';
import 'package:petani/auth/models/email_sign_up_data.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/auth/views/email_login_view.dart';
import 'package:petani/auth/views/email_sign_up_view.dart';
import 'package:petani/auth/views/main_auth_view.dart';
import 'package:petani/auth/views/social_username_view.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/app_toast.dart';

void main() {
  testWidgets('forgot password shows progress while sending the email', (
    tester,
  ) async {
    final resetCompleter = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: EmailLoginView(onPasswordReset: (_) => resetCompleter.future),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'petani@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('email-login-continue-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('forgot-password-button')));
    await tester.pump();

    expect(
      find.byKey(const Key('password-reset-loading-indicator')),
      findsOneWidget,
    );
    expect(find.text('Menghantar pautan...'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('forgot-password-button')))
          .onPressed,
      isNull,
    );

    resetCompleter.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('password-reset-loading-indicator')),
      findsNothing,
    );
    expect(
      find.text('Pautan pemulihan kata laluan telah dihantar.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('auth page slides from below and completes the email UI flow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final authService = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: _AuthTestHost(authService: authService),
      ),
    );

    await tester.tap(find.byKey(const Key('open-auth-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-auth-page')), findsOneWidget);
    expect(find.text('Simpan setiap rekod bersama anda'), findsOneWidget);
    expect(find.text('Daftar dengan E-mel'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-up-with-email-button')));
    await tester.pumpAndSettle();

    expect(find.byType(EmailSignUpView), findsOneWidget);
    expect(
      find.byKey(const Key('main-auth-page'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Pilih nama pengguna anda'), findsOneWidget);
    expect(find.byKey(const Key('email-sign-up-progress')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('auth-progress-segment-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('auth-progress-segment-3')),
      findsNothing,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-sign-up-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('sign-up-username-field')),
      'PetaniMaju',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-sign-up-continue-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('email-sign-up-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('Apakah e-mel anda?'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-sign-up-continue-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-email-field')),
      'e-mel-tidak-sah',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-sign-up-continue-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-email-field')),
      'petani@example.com',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-sign-up-continue-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('email-sign-up-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih kata laluan anda'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('sign-up-password-field')),
      'tanaman123',
    );
    await tester.enterText(
      find.byKey(const Key('sign-up-confirm-password-field')),
      'tanaman123',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('email-sign-up-continue-button')));
    await tester.pumpAndSettle();
    // The confirmation sheet is deliberately scheduled only after the auth
    // route's reverse transition has fully completed.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(EmailSignUpView), findsNothing);
    expect(find.byKey(const Key('app-confirmation-sheet')), findsOneWidget);
    expect(find.text('Semak Emel anda'), findsOneWidget);
    expect(find.textContaining('sahkan akaun anda'), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('app-confirmation-sheet-image')),
                  )
                  .image
              as AssetImage)
          .assetName,
      'assets/images/farmer_phone.png',
    );
    expect(
      find.byKey(const Key('main-auth-page'), skipOffstage: false),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('app-confirmation-sheet-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-auth-page')), findsNothing);

    await tester.tap(find.byKey(const Key('open-auth-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth-sign-in-button')));
    await tester.pumpAndSettle();

    expect(find.byType(EmailLoginView), findsOneWidget);
    expect(find.text('Selamat kembali'), findsOneWidget);
    expect(find.byKey(const Key('email-login-progress')), findsOneWidget);
    expect(
      find.byKey(const Key('main-auth-page'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-login-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'e-mel-tidak-sah',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-login-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'petani@example.com',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-login-continue-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('email-login-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan kata laluan anda'), findsOneWidget);
    expect(find.text('Lupa kata laluan?'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-login-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'tanaman123',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('email-login-continue-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('email-login-continue-button')));
    await tester.pumpAndSettle();

    expect(find.byType(EmailLoginView), findsNothing);
    expect(find.byKey(const Key('main-auth-page')), findsNothing);
  });

  for (final provider in SocialAuthProvider.values) {
    testWidgets('$provider enters the app without asking for name or email', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final authService = _FakeSocialAuthService();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppToastHost(child: child!),
          theme: AppTheme.light,
          home: _AuthTestHost(authService: authService),
        ),
      );

      await tester.tap(find.byKey(const Key('open-auth-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(Key('continue-with-${provider.name}-button')),
      );
      await tester.pumpAndSettle();

      // This fake intentionally has no username: the UI must never reintroduce
      // a required profile form, even when background metadata saving fails.
      expect(authService.savedUsername, isNull);
      expect(authService.isAuthenticated, isTrue);
      expect(find.text('Pilih nama pengguna anda'), findsNothing);
      expect(find.byType(SocialUsernameView), findsNothing);
      expect(find.byType(EmailSignUpView), findsNothing);
      expect(find.byType(EmailLoginView), findsNothing);
      expect(find.byKey(const Key('main-auth-page')), findsNothing);
      expect(find.byKey(const Key('open-auth-button')), findsOneWidget);
    });
  }
}

class _AuthTestHost extends StatelessWidget {
  const _AuthTestHost({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('open-auth-button'),
          onPressed: () => showMainAuthPage(context, authService: authService),
          child: const Text('Log Masuk'),
        ),
      ),
    );
  }
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  AppAuthUser? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isConfigured => true;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> signInWithEmail(EmailLoginData data) async => true;

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {}

  @override
  Future<void> updateUsername(String username) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> signUpWithEmail(EmailSignUpData data) async => true;
}

class _FakeSocialAuthService extends ChangeNotifier implements AuthService {
  AppAuthUser? _user;
  String? savedUsername;

  @override
  AppAuthUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isConfigured => true;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> signInWithEmail(EmailLoginData data) async => true;

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {
    _user = AppAuthUser(
      id: 'social-user',
      email: 'petani@example.com',
      displayName: 'Nama daripada Google',
      provider: provider == SocialAuthProvider.google
          ? AppAuthProvider.google
          : AppAuthProvider.apple,
    );
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> signUpWithEmail(EmailSignUpData data) async => true;

  @override
  Future<void> updateUsername(String username) async {
    savedUsername = username;
    final user = _user!;
    _user = AppAuthUser(
      id: user.id,
      email: user.email,
      displayName: username,
      username: username,
      provider: user.provider,
    );
    notifyListeners();
  }
}
