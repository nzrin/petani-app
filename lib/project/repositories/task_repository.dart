import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/services/local_notification_service.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/task_control_product.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/profile/repositories/notification_settings_repository.dart';
import 'package:petani/shared/services/app_review_service.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class TaskRepository {
  Future<List<PlotTaskRecord>> getAllTasks();

  Future<List<PlotTaskRecord>> getTasks(int plotId);

  Future<PlotTaskRecord> createTask(TaskFormData data);

  Future<PlotTaskRecord> updateTask({
    required int taskId,
    required TaskFormData data,
  });

  Future<PlotTaskRecord> markTaskCompleted({
    required int taskId,
    required int plotId,
  });

  Future<PlotTaskRecord> markTaskIncomplete({
    required int taskId,
    required int plotId,
  });

  Future<PlotTaskRecord> updateControlMethod({
    required int taskId,
    required int plotId,
    required TaskControlMethod method,
    required List<TaskControlProduct> products,
  });

  Future<void> deleteTask({required int taskId, required int plotId});
}

class SqliteTaskRepository implements TaskRepository {
  const SqliteTaskRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<PlotTaskRecord>> getAllTasks() async {
    final database = await _appDatabase.database;
    final plotRows = await database.rawQuery(
      'SELECT DISTINCT plot_id FROM farm_activities ORDER BY plot_id ASC',
    );
    final tasks = <PlotTaskRecord>[];
    for (final row in plotRows) {
      tasks.addAll(await getTasks(row['plot_id'] as int));
    }
    return tasks;
  }

  @override
  Future<List<PlotTaskRecord>> getTasks(int plotId) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''
      SELECT
        farm_activities.id,
        farm_activities.plot_id,
        farm_activities.activity_type,
        farm_activities.control_method,
        farm_activities.scheduled_at,
        farm_activities.status,
        farm_activities.completed_at,
        farm_activities.notes,
        crop_types.code AS crop_code,
        raised_beds.bed_number
      FROM farm_activities
      INNER JOIN plots ON plots.id = farm_activities.plot_id
      INNER JOIN crop_types ON crop_types.id = plots.crop_type_id
      LEFT JOIN farm_activity_raised_beds
        ON farm_activity_raised_beds.activity_id = farm_activities.id
      LEFT JOIN raised_beds
        ON raised_beds.id = farm_activity_raised_beds.raised_bed_id
      WHERE farm_activities.plot_id = ?
      ORDER BY farm_activities.scheduled_at ASC,
        farm_activities.id DESC,
        raised_beds.bed_number ASC
      ''',
      [plotId],
    );

    final builders = <int, _PlotTaskBuilder>{};
    for (final row in rows) {
      final id = row['id'] as int;
      final builder = builders.putIfAbsent(
        id,
        () => _PlotTaskBuilder.fromRow(row),
      );
      final bedNumber = row['bed_number'] as int?;
      if (bedNumber != null) builder.raisedBedNumbers.add(bedNumber);
    }

    final productRows = await database.rawQuery(
      '''
      SELECT
        farm_activity_control_products.activity_id,
        farm_activity_control_products.product_name,
        farm_activity_control_products.product_detail
      FROM farm_activity_control_products
      INNER JOIN farm_activities
        ON farm_activities.id = farm_activity_control_products.activity_id
      WHERE farm_activities.plot_id = ?
      ORDER BY farm_activity_control_products.product_name ASC
      ''',
      [plotId],
    );
    for (final row in productRows) {
      final builder = builders[row['activity_id'] as int];
      if (builder == null) continue;
      builder.controlProducts.add(
        TaskControlProduct(
          name: row['product_name'] as String,
          detail: row['product_detail'] as String,
        ),
      );
    }
    return builders.values.map((builder) => builder.build()).toList();
  }

  @override
  Future<PlotTaskRecord> createTask(TaskFormData data) async {
    final database = await _appDatabase.database;
    final taskId = await database.transaction((transaction) async {
      final id = await transaction.insert('farm_activities', {
        'plot_id': data.plotId,
        'activity_type': data.type.code,
        'control_method': data.controlMethod?.code,
        'scheduled_at': data.scheduledAt.toUtc().toIso8601String(),
        'notes': data.notes.isEmpty ? null : data.notes,
        'status': 'scheduled',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!data.includesAllRaisedBeds) {
        await _saveRaisedBedLinks(transaction, id, data);
      }
      return id;
    });

    final tasks = await getTasks(data.plotId);
    return tasks.firstWhere((task) => task.id == taskId);
  }

  @override
  Future<PlotTaskRecord> updateTask({
    required int taskId,
    required TaskFormData data,
  }) async {
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final existingRows = await transaction.query(
        'farm_activities',
        columns: ['activity_type'],
        where: 'id = ? AND plot_id = ?',
        whereArgs: [taskId, data.plotId],
        limit: 1,
      );
      if (existingRows.isEmpty) throw StateError('Task does not exist.');
      final typeChanged =
          existingRows.single['activity_type'] as String != data.type.code;
      final updatedRows = await transaction.update(
        'farm_activities',
        {
          'activity_type': data.type.code,
          'control_method': typeChanged ? null : data.controlMethod?.code,
          'scheduled_at': data.scheduledAt.toUtc().toIso8601String(),
          'notes': data.notes.isEmpty ? null : data.notes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ? AND plot_id = ?',
        whereArgs: [taskId, data.plotId],
      );
      if (updatedRows == 0) throw StateError('Task does not exist.');

      if (typeChanged) {
        await transaction.delete(
          'farm_activity_control_products',
          where: 'activity_id = ?',
          whereArgs: [taskId],
        );
      }

      await transaction.delete(
        'farm_activity_raised_beds',
        where: 'activity_id = ?',
        whereArgs: [taskId],
      );
      if (!data.includesAllRaisedBeds) {
        await _saveRaisedBedLinks(transaction, taskId, data);
      }
    });

    return _getTask(taskId: taskId, plotId: data.plotId);
  }

  @override
  Future<PlotTaskRecord> markTaskCompleted({
    required int taskId,
    required int plotId,
  }) async {
    final database = await _appDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final updatedRows = await database.update(
      'farm_activities',
      {'status': 'completed', 'completed_at': now, 'updated_at': now},
      where: 'id = ? AND plot_id = ?',
      whereArgs: [taskId, plotId],
    );
    if (updatedRows == 0) throw StateError('Task does not exist.');
    return _getTask(taskId: taskId, plotId: plotId);
  }

  @override
  Future<PlotTaskRecord> markTaskIncomplete({
    required int taskId,
    required int plotId,
  }) async {
    final database = await _appDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final updatedRows = await database.update(
      'farm_activities',
      {'status': 'scheduled', 'completed_at': null, 'updated_at': now},
      where: 'id = ? AND plot_id = ?',
      whereArgs: [taskId, plotId],
    );
    if (updatedRows == 0) throw StateError('Task does not exist.');
    return _getTask(taskId: taskId, plotId: plotId);
  }

  @override
  Future<PlotTaskRecord> updateControlMethod({
    required int taskId,
    required int plotId,
    required TaskControlMethod method,
    required List<TaskControlProduct> products,
  }) async {
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final rows = await transaction.query(
        'farm_activities',
        columns: ['activity_type'],
        where: 'id = ? AND plot_id = ?',
        whereArgs: [taskId, plotId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Task does not exist.');
      final type = FarmTaskType.fromCode(
        rows.single['activity_type'] as String,
      );
      if (!type.supportsControlMethod) {
        throw StateError('This task does not support a control method.');
      }

      final now = DateTime.now().toUtc().toIso8601String();
      await transaction.update(
        'farm_activities',
        {'control_method': method.code, 'updated_at': now},
        where: 'id = ? AND plot_id = ?',
        whereArgs: [taskId, plotId],
      );
      await transaction.delete(
        'farm_activity_control_products',
        where: 'activity_id = ?',
        whereArgs: [taskId],
      );

      if (method == TaskControlMethod.chemical) {
        final batch = transaction.batch();
        for (final product in products) {
          batch.insert('farm_activity_control_products', {
            'activity_id': taskId,
            'product_name': product.name,
            'product_detail': product.detail,
          });
        }
        await batch.commit(noResult: true);
      }
    });
    return _getTask(taskId: taskId, plotId: plotId);
  }

  @override
  Future<void> deleteTask({required int taskId, required int plotId}) async {
    final database = await _appDatabase.database;
    final deletedRows = await database.delete(
      'farm_activities',
      where: 'id = ? AND plot_id = ?',
      whereArgs: [taskId, plotId],
    );
    if (deletedRows == 0) throw StateError('Task does not exist.');
  }

  Future<PlotTaskRecord> _getTask({
    required int taskId,
    required int plotId,
  }) async {
    final tasks = await getTasks(plotId);
    return tasks.firstWhere((task) => task.id == taskId);
  }

  Future<void> _saveRaisedBedLinks(
    Transaction transaction,
    int taskId,
    TaskFormData data,
  ) async {
    if (data.raisedBedIds.isEmpty) {
      throw StateError('At least one raised bed must be selected.');
    }

    final raisedBeds = await transaction.query(
      'raised_beds',
      columns: ['id'],
      where: 'plot_id = ?',
      whereArgs: [data.plotId],
    );
    final validIds = raisedBeds
        .map((row) => row['id'])
        .whereType<int>()
        .toSet();
    if (!validIds.containsAll(data.raisedBedIds)) {
      throw StateError('A selected raised bed does not belong to this plot.');
    }

    final batch = transaction.batch();
    for (final raisedBedId in data.raisedBedIds) {
      batch.insert('farm_activity_raised_beds', {
        'activity_id': taskId,
        'raised_bed_id': raisedBedId,
      });
    }
    await batch.commit(noResult: true);
  }
}

TaskRepository createDefaultTaskRepository() {
  return NotificationTaskRepository(
    SqliteTaskRepository(AppDatabase.instance),
    LocalNotificationService.instance,
    SqliteNotificationSettingsRepository(AppDatabase.instance),
  );
}

class NotificationTaskRepository implements TaskRepository {
  const NotificationTaskRepository(
    this._delegate,
    this._notifications,
    this._settingsRepository,
  );

  final TaskRepository _delegate;
  final LocalNotificationService _notifications;
  final NotificationSettingsRepository _settingsRepository;

  @override
  Future<List<PlotTaskRecord>> getAllTasks() => _delegate.getAllTasks();

  @override
  Future<List<PlotTaskRecord>> getTasks(int plotId) =>
      _delegate.getTasks(plotId);

  @override
  Future<PlotTaskRecord> createTask(TaskFormData data) async {
    final task = await _delegate.createTask(data);
    await _scheduleSafely(task, requestPermission: true);
    unawaited(_requestReviewAfterTaskCreated());
    return task;
  }

  Future<void> _requestReviewAfterTaskCreated() async {
    try {
      final totalTaskCount = (await _delegate.getAllTasks()).length;
      await AppReviewService.instance.requestAfterTaskCreated(
        totalTaskCount: totalTaskCount,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Unable to evaluate the app review prompt: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<PlotTaskRecord> updateTask({
    required int taskId,
    required TaskFormData data,
  }) async {
    final task = await _delegate.updateTask(taskId: taskId, data: data);
    await _scheduleSafely(task);
    return task;
  }

  @override
  Future<PlotTaskRecord> markTaskCompleted({
    required int taskId,
    required int plotId,
  }) async {
    final task = await _delegate.markTaskCompleted(
      taskId: taskId,
      plotId: plotId,
    );
    await _cancelSafely(taskId);
    return task;
  }

  @override
  Future<PlotTaskRecord> markTaskIncomplete({
    required int taskId,
    required int plotId,
  }) async {
    final task = await _delegate.markTaskIncomplete(
      taskId: taskId,
      plotId: plotId,
    );
    await _scheduleSafely(task, requestPermission: true);
    return task;
  }

  @override
  Future<PlotTaskRecord> updateControlMethod({
    required int taskId,
    required int plotId,
    required TaskControlMethod method,
    required List<TaskControlProduct> products,
  }) {
    return _delegate.updateControlMethod(
      taskId: taskId,
      plotId: plotId,
      method: method,
      products: products,
    );
  }

  @override
  Future<void> deleteTask({required int taskId, required int plotId}) async {
    await _delegate.deleteTask(taskId: taskId, plotId: plotId);
    await _cancelSafely(taskId);
  }

  Future<void> _scheduleSafely(
    PlotTaskRecord task, {
    bool requestPermission = false,
  }) async {
    try {
      final settings = await _settingsRepository.getSettings();
      if (!settings.isEnabled) {
        await _notifications.cancelTask(task.id);
        return;
      }
      if (requestPermission && !await _notifications.requestPermissions()) {
        return;
      }
      await _notifications.scheduleTask(task, settings);
    } on Exception {
      // Saving the task must not fail when notifications are unavailable.
    }
  }

  Future<void> _cancelSafely(int taskId) async {
    try {
      await _notifications.cancelTask(taskId);
    } on Exception {
      // Updating the task must not fail when notifications are unavailable.
    }
  }
}

class _PlotTaskBuilder {
  _PlotTaskBuilder({
    required this.id,
    required this.plotId,
    required this.type,
    required this.controlMethod,
    required this.scheduledAt,
    required this.notes,
    required this.isCompleted,
    required this.completedAt,
    required this.cropCode,
  });

  factory _PlotTaskBuilder.fromRow(Map<String, Object?> row) {
    return _PlotTaskBuilder(
      id: row['id'] as int,
      plotId: row['plot_id'] as int,
      type: FarmTaskType.fromCode(row['activity_type'] as String),
      controlMethod: TaskControlMethod.fromCode(
        row['control_method'] as String?,
      ),
      scheduledAt: DateTime.parse(row['scheduled_at'] as String).toLocal(),
      notes: row['notes'] as String? ?? '',
      isCompleted: row['status'] == 'completed',
      completedAt: switch (row['completed_at']) {
        final String value => DateTime.parse(value).toLocal(),
        _ => null,
      },
      cropCode: row['crop_code'] as String,
    );
  }

  final int id;
  final int plotId;
  final FarmTaskType type;
  final TaskControlMethod? controlMethod;
  final DateTime scheduledAt;
  final String notes;
  final bool isCompleted;
  final DateTime? completedAt;
  final String cropCode;
  final List<int> raisedBedNumbers = [];
  final List<TaskControlProduct> controlProducts = [];

  PlotTaskRecord build() {
    return PlotTaskRecord(
      id: id,
      plotId: plotId,
      type: type,
      controlMethod: controlMethod,
      controlProducts: List.unmodifiable(controlProducts),
      scheduledAt: scheduledAt,
      notes: notes,
      raisedBedNumbers: List.unmodifiable(raisedBedNumbers),
      isCompleted: isCompleted,
      completedAt: completedAt,
      cropCode: cropCode,
    );
  }
}
