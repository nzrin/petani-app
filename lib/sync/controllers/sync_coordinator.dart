import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/services/local_notification_service.dart';
import 'package:petani/profile/repositories/notification_settings_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/sync/services/data_sync_service.dart';
import 'package:petani/sync/services/local_snapshot_store.dart';

class SyncCoordinator extends ChangeNotifier with WidgetsBindingObserver {
  SyncCoordinator._();

  static final SyncCoordinator instance = SyncCoordinator._();
  static const syncInterval = Duration(days: 3);

  final _authService = SupabaseAuthService.instance;
  late final DataSyncService _syncService = DataSyncService(
    authService: _authService,
    localStore: LocalSnapshotStore(AppDatabase.instance),
  );

  Timer? _periodicTimer;
  Future<DataSyncResult>? _activeSync;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _authService.addListener(_handleAuthChanged);
    _periodicTimer = Timer.periodic(
      syncInterval,
      (_) => unawaited(synchronizeSafely()),
    );
    if (_authService.isAuthenticated) unawaited(synchronizeSafely());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _authService.isAuthenticated) {
      unawaited(synchronizeSafely());
    }
  }

  void _handleAuthChanged() {
    if (_authService.isAuthenticated) unawaited(synchronizeSafely());
  }

  Future<DataSyncResult> synchronizeSafely() {
    final activeSync = _activeSync;
    if (activeSync != null) return activeSync;
    final operation = _runSync();
    _activeSync = operation;
    return operation.whenComplete(() {
      if (identical(_activeSync, operation)) _activeSync = null;
    });
  }

  Future<DataSyncResult> _runSync() async {
    try {
      final result = await _syncService.synchronize();
      if (result == DataSyncResult.downloaded ||
          result == DataSyncResult.replacedAndUploaded) {
        await _refreshTaskNotifications();
        notifyListeners();
      }
      return result;
    } on Exception {
      // Sync is best effort. SQLite remains the source used by the UI.
      return DataSyncResult.skipped;
    }
  }

  Future<void> _refreshTaskNotifications() async {
    try {
      final tasks = await SqliteTaskRepository(
        AppDatabase.instance,
      ).getAllTasks();
      final settings = await SqliteNotificationSettingsRepository(
        AppDatabase.instance,
      ).getSettings();
      await LocalNotificationService.instance.synchronizeTasks(tasks, settings);
    } on Exception {
      // Notification refresh must not invalidate a completed data sync.
    }
  }

  @override
  void dispose() {
    if (!_initialized) return;
    WidgetsBinding.instance.removeObserver(this);
    _authService.removeListener(_handleAuthChanged);
    _periodicTimer?.cancel();
    _initialized = false;
    super.dispose();
  }
}
