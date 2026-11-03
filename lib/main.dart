import 'package:flutter/material.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/services/local_notification_service.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/main/views/app_session_view.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/profile/repositories/notification_settings_repository.dart';
import 'package:petani/shared/repositories/crop_selection_repository.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:petani/splash/views/splash_view.dart';
import 'package:petani/sync/controllers/sync_coordinator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PetaniApp());
}

Future<void> _initializeApp() async {
  await AppDatabase.instance.initialize();
  await SupabaseAuthService.instance.initialize();
  SyncCoordinator.instance.initialize();
  await _initializeTaskNotifications();
}

Future<void> _initializeTaskNotifications() async {
  try {
    final notifications = LocalNotificationService.instance;
    await notifications.initialize();
    final tasks = await SqliteTaskRepository(
      AppDatabase.instance,
    ).getAllTasks();
    final settings = await SqliteNotificationSettingsRepository(
      AppDatabase.instance,
    ).getSettings();
    await notifications.synchronizeTasks(tasks, settings);
  } on Exception {
    // Notifications are optional; the app and local data remain usable.
  }
}

class PetaniApp extends StatelessWidget {
  const PetaniApp({
    super.key,
    this.cropSelectionRepository,
    this.projectRepository,
    this.homeRepository,
    this.authService,
    this.showSplash = true,
    this.initializeApp,
  });

  final CropSelectionRepository? cropSelectionRepository;
  final ProjectRepository? projectRepository;
  final HomeRepository? homeRepository;
  final AuthService? authService;
  final bool showSplash;
  final Future<void> Function()? initializeApp;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petani',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        return AppToastHost(
          child: Actions(
            actions: <Type, Action<Intent>>{
              EditableTextTapOutsideIntent:
                  CallbackAction<EditableTextTapOutsideIntent>(
                    onInvoke: (intent) {
                      intent.focusNode.unfocus();
                      return null;
                    },
                  ),
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: showSplash
          ? SplashView(
              initializeApp: initializeApp ?? _initializeApp,
              nextPageBuilder: _buildAppSessionView,
            )
          : _buildAppSessionView(context),
    );
  }

  Widget _buildAppSessionView(BuildContext context) {
    return AppSessionView(
      authService: authService ?? SupabaseAuthService.instance,
      cropSelectionRepository: cropSelectionRepository,
      projectRepository: projectRepository,
      homeRepository: homeRepository,
    );
  }
}
