import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/auth/models/app_auth_user.dart';
import 'package:petani/auth/models/email_login_data.dart';
import 'package:petani/auth/models/email_sign_up_data.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/core/models/task_notification_record.dart';
import 'package:petani/core/repositories/notification_history_repository.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/controllers/home_controller.dart';
import 'package:petani/home/models/plot_overview.dart';
import 'package:petani/home/models/task_schedule_record.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/home/views/home_view.dart';
import 'package:petani/project/models/plot_task_record.dart';

void main() {
  testWidgets('home header follows the authenticated username', (tester) async {
    final controller = HomeController(repository: _EmptyHomeRepository());
    final authService = _MutableAuthService();
    addTearDown(controller.dispose);
    addTearDown(authService.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeView(
            controller: controller,
            authService: authService,
            notificationHistoryRepository: _EmptyNotificationRepository(),
          ),
        ),
      ),
    );

    expect(find.text('Petani Moden'), findsOneWidget);

    authService.setUser(
      const AppAuthUser(
        id: 'user-1',
        email: 'nazrin@example.com',
        displayName: 'Nama Paparan',
        username: 'NazrinFarm',
        provider: AppAuthProvider.google,
      ),
    );
    await tester.pump();

    expect(find.text('NazrinFarm'), findsOneWidget);
    expect(find.text('Petani Moden'), findsNothing);

    authService.setUser(
      const AppAuthUser(
        id: 'user-2',
        email: 'private@privaterelay.appleid.com',
        displayName: 'Nama Apple',
        username: 'namaapple_0000000000000000000000001',
        usernameIsGenerated: true,
        provider: AppAuthProvider.apple,
      ),
    );
    await tester.pump();
    expect(find.text('Nama Apple'), findsOneWidget);
    expect(find.text('namaapple_0000000000000000000000001'), findsNothing);
    expect(find.text('private'), findsNothing);

    authService.setUser(null);
    await tester.pump();

    expect(find.text('Petani Moden'), findsOneWidget);
  });
}

class _MutableAuthService extends ChangeNotifier implements AuthService {
  AppAuthUser? _user;

  void setUser(AppAuthUser? user) {
    _user = user;
    notifyListeners();
  }

  @override
  AppAuthUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isConfigured => true;

  @override
  Future<void> deleteAccount() async => setUser(null);

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> signInWithEmail(EmailLoginData data) async => true;

  @override
  Future<void> signInWithProvider(SocialAuthProvider provider) async {}

  @override
  Future<void> signOut() async => setUser(null);

  @override
  Future<bool> signUpWithEmail(EmailSignUpData data) async => true;

  @override
  Future<void> updateUsername(String username) async {}
}

class _EmptyHomeRepository implements HomeRepository {
  @override
  Future<List<PlotOverview>> getPlotOverviews({DateTime? now}) async =>
      const [];

  @override
  Future<List<TaskScheduleRecord>> getScheduledTasksForMonth(
    DateTime month,
  ) async => const [];

  @override
  Future<List<UpcomingTaskRecord>> getUpcomingTasks({
    DateTime? fromDate,
  }) async => const [];
}

class _EmptyNotificationRepository implements NotificationHistoryRepository {
  @override
  Future<void> cancelAllPending({DateTime? now}) async {}

  @override
  Future<void> cancelPendingForTask(int taskId, {DateTime? now}) async {}

  @override
  Future<void> deleteAllReceivedNotifications({DateTime? now}) async {}

  @override
  Future<void> deleteReceivedNotification(int notificationId) async {}

  @override
  Future<List<TaskNotificationRecord>> getReceivedNotifications({
    DateTime? now,
  }) async => const [];

  @override
  Future<bool> hasUnreadNotifications({DateTime? now}) async => false;

  @override
  Future<void> markAllAsRead({DateTime? now}) async {}

  @override
  Future<void> markAsRead(int notificationId) async {}

  @override
  Future<void> saveScheduledNotification({
    required int notificationId,
    required PlotTaskRecord task,
    required String title,
    required String message,
    required DateTime reminderAt,
  }) async {}
}
