import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/models/task_notification_record.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/task_form_data.dart';

abstract interface class NotificationHistoryRepository {
  Future<void> saveScheduledNotification({
    required int notificationId,
    required PlotTaskRecord task,
    required String title,
    required String message,
    required DateTime reminderAt,
  });

  Future<void> cancelPendingForTask(int taskId, {DateTime? now});

  Future<void> cancelAllPending({DateTime? now});

  Future<List<TaskNotificationRecord>> getReceivedNotifications({
    DateTime? now,
  });

  Future<void> markAsRead(int notificationId);

  Future<void> markAllAsRead({DateTime? now});

  Future<void> deleteReceivedNotification(int notificationId);

  Future<void> deleteAllReceivedNotifications({DateTime? now});

  Future<bool> hasUnreadNotifications({DateTime? now});
}

class SqliteNotificationHistoryRepository
    implements NotificationHistoryRepository {
  const SqliteNotificationHistoryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<void> saveScheduledNotification({
    required int notificationId,
    required PlotTaskRecord task,
    required String title,
    required String message,
    required DateTime reminderAt,
  }) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    await database.rawInsert(
      '''
      INSERT INTO task_notification_history (
        notification_id,
        task_id,
        plot_id,
        task_type,
        crop_code,
        title,
        message,
        reminder_at,
        task_scheduled_at,
        is_read,
        canceled_at,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NULL, ?)
      ON CONFLICT(task_id, reminder_at) DO UPDATE SET
        notification_id = excluded.notification_id,
        plot_id = excluded.plot_id,
        task_type = excluded.task_type,
        crop_code = excluded.crop_code,
        title = excluded.title,
        message = excluded.message,
        task_scheduled_at = excluded.task_scheduled_at,
        is_read = 0,
        canceled_at = NULL
      ''',
      [
        notificationId,
        task.id,
        task.plotId,
        task.type.code,
        task.cropCode,
        title,
        message,
        reminderAt.toUtc().toIso8601String(),
        task.scheduledAt.toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> cancelPendingForTask(int taskId, {DateTime? now}) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final canceledAt = (now ?? DateTime.now()).toUtc().toIso8601String();
    await database.update(
      'task_notification_history',
      {'canceled_at': canceledAt},
      where: 'task_id = ? AND reminder_at > ? AND canceled_at IS NULL',
      whereArgs: [taskId, canceledAt],
    );
  }

  @override
  Future<void> cancelAllPending({DateTime? now}) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final canceledAt = (now ?? DateTime.now()).toUtc().toIso8601String();
    await database.update(
      'task_notification_history',
      {'canceled_at': canceledAt},
      where: 'reminder_at > ? AND canceled_at IS NULL',
      whereArgs: [canceledAt],
    );
  }

  @override
  Future<List<TaskNotificationRecord>> getReceivedNotifications({
    DateTime? now,
  }) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final currentTime = (now ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await database.rawQuery(
      '''
      SELECT
        task_notification_history.id,
        task_notification_history.task_id,
        task_notification_history.plot_id,
        task_notification_history.task_type,
        task_notification_history.crop_code,
        task_notification_history.title,
        task_notification_history.message,
        task_notification_history.reminder_at,
        task_notification_history.task_scheduled_at,
        task_notification_history.is_read,
        COALESCE(plots.project_name, '') AS project_name,
        COALESCE(plots.name, '') AS plot_name,
        CASE WHEN farm_activities.id IS NULL THEN 0 ELSE 1 END
          AS is_task_available
      FROM task_notification_history
      LEFT JOIN farm_activities
        ON farm_activities.id = task_notification_history.task_id
        AND farm_activities.plot_id = task_notification_history.plot_id
      LEFT JOIN plots ON plots.id = task_notification_history.plot_id
      WHERE task_notification_history.reminder_at <= ?
        AND task_notification_history.canceled_at IS NULL
      ORDER BY task_notification_history.reminder_at DESC,
        task_notification_history.id DESC
      ''',
      [currentTime],
    );

    return rows
        .map(
          (row) => TaskNotificationRecord(
            id: row['id'] as int,
            taskId: row['task_id'] as int,
            plotId: row['plot_id'] as int,
            type: FarmTaskType.fromCode(row['task_type'] as String),
            cropCode: row['crop_code'] as String,
            title: row['title'] as String,
            message: row['message'] as String,
            receivedAt: DateTime.parse(row['reminder_at'] as String).toLocal(),
            taskScheduledAt: DateTime.parse(
              row['task_scheduled_at'] as String,
            ).toLocal(),
            projectName: row['project_name'] as String,
            plotName: row['plot_name'] as String,
            isTaskAvailable: row['is_task_available'] as int == 1,
            isRead: row['is_read'] as int == 1,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final updatedRows = await database.update(
      'task_notification_history',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
    if (updatedRows == 0) {
      throw StateError('Notification $notificationId does not exist.');
    }
  }

  @override
  Future<void> markAllAsRead({DateTime? now}) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final currentTime = (now ?? DateTime.now()).toUtc().toIso8601String();
    await database.update(
      'task_notification_history',
      {'is_read': 1},
      where: 'reminder_at <= ? AND canceled_at IS NULL',
      whereArgs: [currentTime],
    );
  }

  @override
  Future<void> deleteAllReceivedNotifications({DateTime? now}) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final currentTime = (now ?? DateTime.now()).toUtc().toIso8601String();
    await database.delete(
      'task_notification_history',
      where: 'reminder_at <= ?',
      whereArgs: [currentTime],
    );
  }

  @override
  Future<void> deleteReceivedNotification(int notificationId) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final deletedRows = await database.delete(
      'task_notification_history',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
    if (deletedRows == 0) {
      throw StateError('Notification $notificationId does not exist.');
    }
  }

  @override
  Future<bool> hasUnreadNotifications({DateTime? now}) async {
    final database = await _appDatabase.ensureTaskNotificationHistorySchema();
    final currentTime = (now ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await database.query(
      'task_notification_history',
      columns: ['id'],
      where: 'reminder_at <= ? AND canceled_at IS NULL AND is_read = 0',
      whereArgs: [currentTime],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
