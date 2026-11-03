import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/auth/models/app_auth_user.dart';
import 'package:petani/auth/models/email_login_data.dart';
import 'package:petani/auth/models/email_sign_up_data.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/main/views/app_session_view.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/repositories/crop_selection_repository.dart';

void main() {
  testWidgets('restored account session opens the main app', (tester) async {
    final authService = _MutableAuthService(authenticated: true);
    final cropRepository = _MemoryCropSelectionRepository('coconut');
    addTearDown(authService.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppSessionView(
          authService: authService,
          cropSelectionRepository: cropRepository,
          authenticatedAppBuilder: (_, crop, _) => Text('Main ${crop.name}'),
          walkthroughBuilder: (_, _) => const Text('Walkthrough'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Main Kelapa'), findsOneWidget);
    expect(find.text('Walkthrough'), findsNothing);

    await authService.signOut();
    await tester.pump();

    expect(find.text('Walkthrough'), findsOneWidget);
    expect(find.text('Main Kelapa'), findsNothing);
  });

  testWidgets('signed-out startup opens the walkthrough', (tester) async {
    final authService = _MutableAuthService(authenticated: false);
    addTearDown(authService.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppSessionView(
          authService: authService,
          cropSelectionRepository: _MemoryCropSelectionRepository('coconut'),
          authenticatedAppBuilder: (_, crop, _) => Text('Main ${crop.name}'),
          walkthroughBuilder: (_, _) => const Text('Walkthrough'),
        ),
      ),
    );

    expect(find.text('Walkthrough'), findsOneWidget);
    expect(find.text('Main Kelapa'), findsNothing);
  });
}

class _MemoryCropSelectionRepository implements CropSelectionRepository {
  _MemoryCropSelectionRepository(this.selectedCropCode);

  String? selectedCropCode;

  @override
  Future<void> clearSelectedCrop() async => selectedCropCode = null;

  @override
  Future<String?> getSelectedCropCode() async => selectedCropCode;

  @override
  Future<void> saveSelectedCrop(CropOption crop) async {
    selectedCropCode = crop.code;
  }
}

class _MutableAuthService extends ChangeNotifier implements AuthService {
  _MutableAuthService({required bool authenticated})
    : _user = authenticated
          ? const AppAuthUser(
              id: 'restored-user',
              email: 'petani@example.com',
              provider: AppAuthProvider.email,
            )
          : null;

  AppAuthUser? _user;

  @override
  AppAuthUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isConfigured => true;

  @override
  Future<void> deleteAccount() async => signOut();

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> signInWithEmail(EmailLoginData data) async => true;

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> signUpWithEmail(EmailSignUpData data) async => true;

  @override
  Future<void> updateUsername(String username) async {}
}
