import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/auth/models/app_auth_user.dart';
import 'package:petani/auth/models/email_login_data.dart';
import 'package:petani/auth/models/email_sign_up_data.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/views/profile_view.dart';

void main() {
  testWidgets('authenticated profile confirms logout through Supabase', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final authService = _FakeAuthenticatedAuthService();
    var logoutNavigationCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfileView(
            authService: authService,
            onLogout: () => logoutNavigationCount++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('profile-login-card')), findsNothing);
    expect(find.byKey(const Key('logout-button')), findsOneWidget);
    expect(find.byKey(const Key('delete-account-button')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('logout-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Log Keluar?'), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('app-confirmation-sheet-image')),
                  )
                  .image
              as AssetImage)
          .assetName,
      'assets/images/farmer_logout.png',
    );
    expect(authService.signOutCalls, 0);
    await tester.tap(
      find.byKey(const Key('app-confirmation-sheet-confirm-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(authService.signOutCalls, 1);
    expect(logoutNavigationCount, 1);
  });

  testWidgets('authenticated profile confirms permanent account deletion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final authService = _FakeAuthenticatedAuthService();
    var logoutNavigationCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfileView(
            authService: authService,
            onLogout: () => logoutNavigationCount++,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('delete-account-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('delete-account-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Padam Akaun?'), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('app-confirmation-sheet-image')),
                  )
                  .image
              as AssetImage)
          .assetName,
      'assets/images/farmer_delete_account.png',
    );
    expect(authService.deleteAccountCalls, 0);
    await tester.tap(
      find.byKey(const Key('app-confirmation-sheet-confirm-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const Key('delete-account-confirmation-sheet')),
      findsOneWidget,
    );
    expect(find.text('Padam akaun secara kekal?'), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('delete-account-confirmation-image')),
                  )
                  .image
              as AssetImage)
          .assetName,
      'assets/images/trash.png',
    );
    expect(authService.deleteAccountCalls, 0);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('delete-account-permanently-button')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('delete-account-confirmation-field')),
      'PADAM',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('delete-account-permanently-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(authService.deleteAccountCalls, 1);
    expect(logoutNavigationCount, 1);
  });
}

class _FakeAuthenticatedAuthService extends ChangeNotifier
    implements AuthService {
  AppAuthUser? _user = const AppAuthUser(
    id: 'user-1',
    email: 'petani@example.com',
    provider: AppAuthProvider.email,
  );

  int signOutCalls = 0;
  int deleteAccountCalls = 0;

  @override
  AppAuthUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isConfigured => true;

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalls++;
    _user = null;
    notifyListeners();
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> signInWithEmail(EmailLoginData data) async => true;

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {}

  @override
  Future<void> updateUsername(String username) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> signUpWithEmail(EmailSignUpData data) async => true;
}
