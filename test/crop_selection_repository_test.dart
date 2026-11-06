import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/repositories/notification_history_repository.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/project/controllers/project_form_controller.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/models/task_control_product.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/profile/models/notification_reminder_settings.dart';
import 'package:petani/profile/models/notification_sound_option.dart';
import 'package:petani/profile/repositories/notification_settings_repository.dart';
import 'package:petani/report/models/report_summary.dart';
import 'package:petani/report/repositories/report_repository.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/repositories/crop_selection_repository.dart';
import 'package:petani/sync/services/local_snapshot_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
  });

  test('creates the local farm schema with English identifiers', () async {
    final database = await AppDatabase.instance.database;
    final tableRows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tableRows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();

    expect(
      tableNames,
      containsAll({
        'crop_types',
        'plots',
        'plot_varieties',
        'raised_beds',
        'raised_bed_varieties',
        'plant_rows',
        'farm_activities',
        'farm_activity_raised_beds',
        'farm_activity_control_products',
        'disease_reports',
        'app_settings',
        'task_notification_history',
      }),
    );

    final cropRows = await database.query(
      'crop_types',
      columns: ['code', 'asset_path', 'is_available'],
      orderBy: 'id ASC',
    );
    expect(cropRows.first['code'], 'pineapple');
    expect(
      cropRows.map((row) => row['asset_path']),
      everyElement(startsWith('assets/images/seeds/')),
    );
    final coconut = cropRows.firstWhere((row) => row['code'] == 'coconut');
    expect(coconut['is_available'], 1);

    final plotColumns = await database.rawQuery('PRAGMA table_info(plots)');
    final plotColumnNames = plotColumns
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    expect(
      plotColumnNames,
      containsAll({
        'project_name',
        'variety_code',
        'variety_name',
        'raised_bed_count',
      }),
    );

    final activityColumns = await database.rawQuery(
      'PRAGMA table_info(farm_activities)',
    );
    final activityColumnNames = activityColumns
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    expect(activityColumnNames, contains('control_method'));

    final notificationColumns = await database.rawQuery(
      'PRAGMA table_info(task_notification_history)',
    );
    expect(notificationColumns.map((row) => row['name']), contains('is_read'));

    final syncTriggers = await database.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'trigger' AND name LIKE 'track_sync_%'",
    );
    expect(syncTriggers, hasLength(AppDatabase.syncableTableNames.length * 3));

    expect(ProjectFormController.coconutVarieties, hasLength(16));
    expect(
      ProjectFormController.coconutVarieties.map((variety) => variety.code),
      orderedEquals(List.generate(16, (index) => 'CN${index + 1}')),
    );
    expect(ProjectFormController.coconutVarieties[11].name, 'Rennal Tall Gold');
  });

  test('stores and clears the selected crop code in SQLite', () async {
    const pineapple = CropOption(
      code: 'pineapple',
      name: 'Nanas',
      description: 'Urus plot dan jadual tanaman nanas.',
      isAvailable: true,
      icon: Icons.eco_rounded,
    );
    final repository = SqliteCropSelectionRepository(AppDatabase.instance);

    await repository.clearSelectedCrop();
    await repository.saveSelectedCrop(pineapple);
    expect(await repository.getSelectedCropCode(), 'pineapple');

    await repository.clearSelectedCrop();
    expect(await repository.getSelectedCropCode(), isNull);
  });

  test('stores task reminder lead time in SQLite', () async {
    final repository = SqliteNotificationSettingsRepository(
      AppDatabase.instance,
    );
    final database = await AppDatabase.instance.database;
    await database.delete(
      'app_settings',
      where: 'setting_key LIKE ?',
      whereArgs: ['task_reminder_%'],
    );

    final defaults = await repository.getSettings();
    expect(defaults.isEnabled, isTrue);
    expect(defaults.amount, 12);
    expect(defaults.unit, ReminderTimeUnit.hours);
    expect(defaults.leadTime, const Duration(hours: 12));
    expect(defaults.isSoundEnabled, isTrue);
    expect(defaults.soundId, NotificationSoundOption.defaultId);

    const settings = NotificationReminderSettings(
      isEnabled: true,
      amount: 45,
      unit: ReminderTimeUnit.minutes,
      isSoundEnabled: false,
      soundId: 'lembu',
    );

    await repository.saveSettings(settings);
    final stored = await repository.getSettings();

    expect(stored.isEnabled, isTrue);
    expect(stored.amount, 45);
    expect(stored.unit, ReminderTimeUnit.minutes);
    expect(stored.leadTime, const Duration(minutes: 45));
    expect(stored.isSoundEnabled, isFalse);
    expect(stored.soundId, 'lembu');
    expect(
      stored.notificationMessageFor(DateTime(2026, 10, 24, 7, 30)),
      'Ini adalah peringatan mesra berkenaan tugasan yang telah anda '
      'rekodkan. Tugasan ini dijadualkan akan bermula pada pukul '
      '7:30 pagi, 24 Oktober 2026.',
    );

    await repository.saveSettings(NotificationReminderSettings.defaults);
  });

  test(
    'notification history only returns reminders that were received',
    () async {
      final database = await AppDatabase.instance.database;
      await database.delete(
        'task_notification_history',
        where: 'task_id IN (?, ?)',
        whereArgs: [9001, 9002],
      );
      addTearDown(
        () => database.delete(
          'task_notification_history',
          where: 'task_id IN (?, ?)',
          whereArgs: [9001, 9002],
        ),
      );

      final repository = SqliteNotificationHistoryRepository(
        AppDatabase.instance,
      );
      final now = DateTime(2026, 9, 24, 10);
      final pastTask = PlotTaskRecord(
        id: 9001,
        plotId: 9001,
        type: FarmTaskType.insectControl,
        scheduledAt: DateTime(2026, 9, 24, 10, 30),
        notes: '',
        raisedBedNumbers: const [],
        isCompleted: false,
        completedAt: null,
      );
      final futureTask = PlotTaskRecord(
        id: 9002,
        plotId: 9002,
        type: FarmTaskType.fertilizing,
        scheduledAt: DateTime(2026, 9, 24, 12),
        notes: '',
        raisedBedNumbers: const [],
        isCompleted: false,
        completedAt: null,
      );
      await repository.saveScheduledNotification(
        notificationId: 1009001,
        task: pastTask,
        title: pastTask.type.label,
        message: 'Peringatan terdahulu',
        reminderAt: DateTime(2026, 9, 24, 9),
      );
      await repository.saveScheduledNotification(
        notificationId: 1009002,
        task: futureTask,
        title: futureTask.type.label,
        message: 'Peringatan akan datang',
        reminderAt: DateTime(2026, 9, 24, 11),
      );

      final received = await repository.getReceivedNotifications(now: now);
      expect(received.map((item) => item.taskId), [9001]);
      expect(received.single.isRead, isFalse);
      expect(await repository.hasUnreadNotifications(now: now), isTrue);

      await repository.markAsRead(received.single.id);
      final readNotifications = await repository.getReceivedNotifications(
        now: now,
      );
      expect(readNotifications.single.isRead, isTrue);
      expect(await repository.hasUnreadNotifications(now: now), isFalse);

      await repository.cancelPendingForTask(9002, now: now);
      final afterFutureTime = await repository.getReceivedNotifications(
        now: DateTime(2026, 9, 24, 12),
      );
      expect(afterFutureTime.map((item) => item.taskId), [9001]);

      await repository.saveScheduledNotification(
        notificationId: 1009001,
        task: pastTask,
        title: pastTask.type.label,
        message: 'Peringatan terdahulu',
        reminderAt: DateTime(2026, 9, 24, 9),
      );
      expect(await repository.hasUnreadNotifications(now: now), isTrue);
      await repository.markAllAsRead(now: now);
      expect(await repository.hasUnreadNotifications(now: now), isFalse);

      final notificationToDelete = (await repository.getReceivedNotifications(
        now: now,
      )).single;
      await repository.deleteReceivedNotification(notificationToDelete.id);
      expect(await repository.getReceivedNotifications(now: now), isEmpty);

      await repository.saveScheduledNotification(
        notificationId: 1009001,
        task: pastTask,
        title: pastTask.type.label,
        message: 'Peringatan terdahulu',
        reminderAt: DateTime(2026, 9, 24, 9),
      );
      await repository.deleteAllReceivedNotifications(now: now);
      expect(await repository.getReceivedNotifications(now: now), isEmpty);
    },
  );

  test('stores the project setup form as a plot in SQLite', () async {
    final database = await AppDatabase.instance.database;
    await database.delete('plots');
    final repository = SqliteProjectRepository(AppDatabase.instance);
    final plotId = await repository.createProject(
      ProjectFormData(
        cropCode: 'pineapple',
        projectName: 'Projek Integrasi Nanas',
        location: 'Pontian, Johor',
        plotName: 'Plot A',
        varieties: const [
          CropVariety(code: 'AC1', name: 'Moris'),
          CropVariety(code: 'AC5', name: 'Josapine'),
        ],
        raisedBedCount: 12,
        plantedAt: DateTime(2026, 9, 22),
      ),
    );
    final secondPlotId = await repository.createProject(
      ProjectFormData(
        cropCode: 'pineapple',
        projectName: 'Projek Integrasi Nanas',
        location: 'Pontian, Johor',
        plotName: 'Plot B',
        varieties: const [CropVariety(code: 'AC9', name: 'MD2')],
        raisedBedCount: 8,
        plantedAt: DateTime(2026, 10, 1),
      ),
    );
    final coconutPlotId = await repository.createProject(
      ProjectFormData(
        cropCode: 'coconut',
        projectName: 'Projek Integrasi Nanas',
        location: 'Lokasi ini mesti diabaikan',
        plotName: 'Plot Kelapa',
        varieties: const [CropVariety(code: 'CN13', name: 'Matag Green')],
        raisedBedCount: 4,
        plantedAt: DateTime(2026, 10, 2),
      ),
    );

    final rows = await database.query(
      'plots',
      where: 'id = ?',
      whereArgs: [plotId],
      limit: 1,
    );

    expect(rows.single['project_name'], 'Projek Integrasi Nanas');
    expect(rows.single['name'], 'Plot A');
    expect(rows.single['variety_code'], 'AC1');
    expect(rows.single['raised_bed_count'], 12);

    final varietyRows = await database.query(
      'plot_varieties',
      columns: ['variety_code'],
      where: 'plot_id = ?',
      whereArgs: [plotId],
      orderBy: 'id ASC',
    );
    expect(
      varietyRows.map((row) => row['variety_code']),
      orderedEquals(['AC1', 'AC5']),
    );

    final raisedBedRepository = SqliteRaisedBedRepository(AppDatabase.instance);
    final initialRaisedBeds = await raisedBedRepository.getRaisedBeds(plotId);
    expect(initialRaisedBeds, hasLength(12));
    expect(
      initialRaisedBeds.every((raisedBed) => !raisedBed.isConfigured),
      isTrue,
    );
    expect(
      initialRaisedBeds.every((raisedBed) => raisedBed.varieties.isEmpty),
      isTrue,
    );

    await raisedBedRepository.saveRaisedBedDetails(
      plotId: plotId,
      bedNumber: 2,
      seedlingCount: 0,
      varieties: const [
        CropVariety(code: 'AC1', name: 'Moris'),
        CropVariety(code: 'AC5', name: 'Josapine'),
      ],
    );
    final raisedBedsWithVarieties = await raisedBedRepository.getRaisedBeds(
      plotId,
    );
    expect(raisedBedsWithVarieties[1].seedlingCount, isNull);
    expect(
      raisedBedsWithVarieties[1].varieties.map((variety) => variety.code),
      orderedEquals(['AC1', 'AC5']),
    );

    await raisedBedRepository.saveSeedlingCount(
      plotId: plotId,
      bedNumber: 1,
      seedlingCount: 500,
    );
    await raisedBedRepository.saveBulkRaisedBedDetails(
      plotId: plotId,
      seedlingCount: 300,
      onlyUnset: true,
      varieties: const [CropVariety(code: 'AC5', name: 'Josapine')],
    );
    final configuredRaisedBeds = await raisedBedRepository.getRaisedBeds(
      plotId,
    );
    expect(configuredRaisedBeds.first.seedlingCount, 500);
    expect(
      configuredRaisedBeds
          .skip(1)
          .every((raisedBed) => raisedBed.seedlingCount == 300),
      isTrue,
    );
    expect(configuredRaisedBeds.first.varieties, isEmpty);
    expect(
      configuredRaisedBeds
          .skip(1)
          .every(
            (raisedBed) =>
                raisedBed.varieties.length == 1 &&
                raisedBed.varieties.single.code == 'AC5',
          ),
      isTrue,
    );
    await raisedBedRepository.saveSeedlingCount(
      plotId: plotId,
      bedNumber: 1,
      seedlingCount: 0,
    );
    final clearedRaisedBeds = await raisedBedRepository.getRaisedBeds(plotId);
    expect(clearedRaisedBeds.first.seedlingCount, isNull);
    expect(clearedRaisedBeds.first.isConfigured, isFalse);

    final taskRepository = SqliteTaskRepository(AppDatabase.instance);
    await taskRepository.createTask(
      TaskFormData(
        plotId: plotId,
        type: FarmTaskType.fertilizing,
        includesAllRaisedBeds: false,
        raisedBedIds: {initialRaisedBeds[0].id, initialRaisedBeds[2].id},
        scheduledAt: DateTime(2026, 10, 5, 9, 15),
        notes: 'Baja mengikut jadual plot.',
      ),
    );
    await taskRepository.createTask(
      TaskFormData(
        plotId: plotId,
        type: FarmTaskType.bedCleaning,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: DateTime(2026, 10, 6),
        notes: '',
      ),
    );
    final tasks = await taskRepository.getTasks(plotId);
    expect(tasks, hasLength(2));
    expect(tasks.first.type, FarmTaskType.fertilizing);
    expect(tasks.first.scheduledAt, DateTime(2026, 10, 5, 9, 15));
    expect(tasks.first.controlMethod, isNull);
    expect(tasks.first.raisedBedNumbers, orderedEquals([1, 3]));
    final controlledTask = await taskRepository.updateControlMethod(
      taskId: tasks.first.id,
      plotId: plotId,
      method: TaskControlMethod.chemical,
      products: const [
        TaskControlProduct(
          name: 'Baja Sebatian NPK Seimbang',
          detail: 'NPK 15-15-15',
        ),
        TaskControlProduct(name: 'Urea', detail: '46% Nitrogen'),
      ],
    );
    expect(controlledTask.controlMethod, TaskControlMethod.chemical);
    expect(controlledTask.controlProducts, hasLength(2));
    expect(
      controlledTask.controlProducts.map((product) => product.detail),
      containsAll(['NPK 15-15-15', '46% Nitrogen']),
    );
    expect(tasks.last.includesAllRaisedBeds, isTrue);
    final updatedTask = await taskRepository.updateTask(
      taskId: tasks.first.id,
      data: TaskFormData(
        plotId: plotId,
        type: FarmTaskType.weedControl,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: DateTime(2026, 10, 7),
        notes: 'Kawalan rumpai dikemas kini.',
      ),
    );
    expect(updatedTask.type, FarmTaskType.weedControl);
    expect(updatedTask.controlMethod, isNull);
    expect(updatedTask.controlProducts, isEmpty);
    final organicTask = await taskRepository.updateControlMethod(
      taskId: updatedTask.id,
      plotId: plotId,
      method: TaskControlMethod.organic,
      products: const [],
    );
    expect(organicTask.controlMethod, TaskControlMethod.organic);
    expect(updatedTask.includesAllRaisedBeds, isTrue);
    var completedTask = await taskRepository.markTaskCompleted(
      taskId: tasks.last.id,
      plotId: plotId,
    );
    expect(completedTask.isCompleted, isTrue);
    expect(completedTask.completedAt, isNotNull);
    final reopenedTask = await taskRepository.markTaskIncomplete(
      taskId: completedTask.id,
      plotId: plotId,
    );
    expect(reopenedTask.isCompleted, isFalse);
    expect(reopenedTask.completedAt, isNull);
    completedTask = await taskRepository.markTaskCompleted(
      taskId: reopenedTask.id,
      plotId: plotId,
    );
    expect(completedTask.isCompleted, isTrue);
    expect(completedTask.completedAt, isNotNull);
    await taskRepository.deleteTask(taskId: updatedTask.id, plotId: plotId);
    final remainingTasks = await taskRepository.getTasks(plotId);
    expect(remainingTasks, hasLength(1));
    expect(remainingTasks.single.id, completedTask.id);

    final reportNow = DateTime.now();
    final reportToday = DateTime(
      reportNow.year,
      reportNow.month,
      reportNow.day,
    );
    final pendingDate = reportToday.add(const Duration(days: 1));
    final overdueDate = reportToday.subtract(const Duration(days: 1));
    await taskRepository.createTask(
      TaskFormData(
        plotId: plotId,
        type: FarmTaskType.fertilizing,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: pendingDate,
        notes: '',
      ),
    );
    await taskRepository.createTask(
      TaskFormData(
        plotId: plotId,
        type: FarmTaskType.weedControl,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: overdueDate,
        notes: '',
      ),
    );
    final report = await SqliteReportRepository(
      AppDatabase.instance,
    ).getDashboard(now: reportNow, year: reportNow.year);
    expect(report.totalPlants, 3300);
    expect(report.projectCount, 1);
    expect(report.plotCount, 3);
    expect(report.completedTasksThisMonth, 1);
    expect(
      report.taskStatistics.valuesFor(
        TaskReportStatus.completed,
      )[completedTask.scheduledAt.month - 1],
      1,
    );
    expect(
      report.taskStatistics.valuesFor(
        TaskReportStatus.pending,
      )[pendingDate.month - 1],
      1,
    );
    expect(
      report.taskStatistics.valuesFor(
        TaskReportStatus.overdue,
      )[overdueDate.month - 1],
      1,
    );
    expect(report.taskTrend.scheduled[pendingDate.month - 1], greaterThan(0));
    expect(report.taskTrend.scheduled[overdueDate.month - 1], greaterThan(0));
    expect(report.taskTrend.completed[completedTask.scheduledAt.month - 1], 1);
    expect(report.plantingTrend.plantCount[8], 3300);

    final pineappleCropType = await database.query(
      'crop_types',
      columns: ['id'],
      where: 'code = ?',
      whereArgs: ['pineapple'],
      limit: 1,
    );
    for (var index = 1; index <= 3; index++) {
      await database.insert('plots', {
        'crop_type_id': pineappleCropType.single['id'],
        'project_name': 'Projek Arkib',
        'name': 'Plot Arkib $index',
        'location': 'Johor',
        'variety_code': 'AC1',
        'variety_name': 'Moris',
        'raised_bed_count': 1,
        'planted_at': DateTime(2020, 1, index).toUtc().toIso8601String(),
        'created_at': DateTime(2020, 1, index).toUtc().toIso8601String(),
        'updated_at': DateTime(2020, 1, index).toUtc().toIso8601String(),
      });
    }

    final homeRepository = SqliteHomeRepository(AppDatabase.instance);
    final plotOverviews = await homeRepository.getPlotOverviews(
      now: DateTime(2026, 9, 24),
    );
    expect(plotOverviews, hasLength(5));
    expect(plotOverviews.map((overview) => overview.plotName), [
      'Plot Kelapa',
      'Plot B',
      'Plot A',
      'Plot Arkib 3',
      'Plot Arkib 2',
    ]);
    final pineappleOverview = plotOverviews.firstWhere(
      (overview) => overview.plotName == 'Plot A',
    );
    expect(pineappleOverview.projectName, 'Projek Integrasi Nanas');
    expect(pineappleOverview.totalPlants, 3300);
    expect(pineappleOverview.daysToHarvest, 363);
    final coconutOverview = plotOverviews.first;
    expect(coconutOverview.totalPlants, 0);
    expect(coconutOverview.daysToHarvest, isNull);
    expect(coconutOverview.estimatedHarvestAt, isNull);

    final upcomingTasks = await homeRepository.getUpcomingTasks(
      fromDate: reportToday,
    );
    expect(upcomingTasks, hasLength(1));
    expect(upcomingTasks.single.type, FarmTaskType.fertilizing);
    expect(upcomingTasks.single.projectName, 'Projek Integrasi Nanas');
    expect(upcomingTasks.single.plotName, 'Plot A');
    expect(upcomingTasks.single.location, 'Pontian, Johor');

    final scheduledTasks = await homeRepository.getScheduledTasksForMonth(
      completedTask.scheduledAt,
    );
    expect(
      scheduledTasks.any(
        (task) => task.id == completedTask.id && task.isCompleted,
      ),
      isTrue,
    );

    final coconutTask = await taskRepository.createTask(
      TaskFormData(
        plotId: coconutPlotId,
        cropCode: 'coconut',
        type: FarmTaskType.bedCleaning,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: DateTime(2026, 10, 8),
        notes: '',
      ),
    );
    expect(coconutTask.cropCode, 'coconut');
    expect(
      coconutTask.type.labelForCrop(coconutTask.cropCode),
      'Mencuci Baris',
    );
    expect(coconutTask.raisedBedSummary(4), 'Semua 4 baris');
    await taskRepository.deleteTask(
      taskId: coconutTask.id,
      plotId: coconutPlotId,
    );

    await repository.updatePlot(
      plotId: secondPlotId,
      data: ProjectFormData(
        cropCode: 'coconut',
        projectName: 'Projek Integrasi Nanas',
        location: 'Pontian, Johor',
        plotName: 'Plot B Dikemas Kini',
        varieties: const [CropVariety(code: 'CN13', name: 'Matag Green')],
        raisedBedCount: 10,
        plantedAt: DateTime(2026, 10, 2),
      ),
    );
    final updatedRaisedBeds = await raisedBedRepository.getRaisedBeds(
      secondPlotId,
    );
    expect(updatedRaisedBeds, hasLength(10));

    final projects = await repository.getProjects();
    final project = projects.firstWhere(
      (project) => project.plots.any((plot) => plot.id == plotId),
    );
    final plot = project.plots.firstWhere((plot) => plot.id == plotId);
    final updatedPlot = project.plots.firstWhere(
      (plot) => plot.id == secondPlotId,
    );
    expect(project.projectName, 'Projek Integrasi Nanas');
    expect(project.location, 'Pontian, Johor');
    expect(
      project.cropTypes.map((crop) => crop.name),
      containsAll(['Nanas', 'Kelapa']),
    );
    expect(project.plots, hasLength(3));
    expect(
      project.plots.map((plot) => plot.name),
      containsAll(['Plot A', 'Plot B Dikemas Kini', 'Plot Kelapa']),
    );
    expect(plot.name, 'Plot A');
    expect(plot.cropName, 'Nanas');
    expect(plot.imagePath, 'assets/images/seeds/pineapple_fruit.png');
    expect(plot.raisedBedCount, 12);
    expect(updatedPlot.name, 'Plot B Dikemas Kini');
    expect(updatedPlot.cropCode, 'coconut');
    expect(updatedPlot.raisedBedCount, 10);
    expect(updatedPlot.varieties.single.code, 'CN13');
    expect(
      plot.varieties.map((variety) => variety.code),
      orderedEquals(['AC1', 'AC5']),
    );
    expect(plot.plantedAt, DateTime(2026, 9, 22));

    final suggestions = await repository.getFormSuggestions();
    expect(
      suggestions.existingProjects.map((project) => project.name),
      contains('Projek Integrasi Nanas'),
    );
    final projectSuggestion = suggestions.existingProjects.firstWhere(
      (project) => project.name == 'Projek Integrasi Nanas',
    );
    expect(projectSuggestion.location, 'Pontian, Johor');
    expect(
      projectSuggestion.plotNames,
      containsAll(['Plot A', 'Plot B Dikemas Kini', 'Plot Kelapa']),
    );
    expect(suggestions.locations, contains('Pontian, Johor'));
    await expectLater(
      repository.createProject(
        ProjectFormData(
          cropCode: 'pineapple',
          projectName: ' projek integrasi nanas ',
          location: 'Pontian, Johor',
          plotName: ' plot   a ',
          varieties: const [CropVariety(code: 'AC1', name: 'Moris')],
          raisedBedCount: 1,
          plantedAt: DateTime(2026, 10, 3),
        ),
      ),
      throwsStateError,
    );

    final coconutRows = await database.query(
      'plots',
      columns: ['location'],
      where: 'id = ?',
      whereArgs: [coconutPlotId],
    );
    expect(coconutRows.single['location'], 'Pontian, Johor');

    await repository.updateProject(
      currentProjectName: 'Projek Integrasi Nanas',
      projectName: 'Projek Integrasi Dikemas Kini',
      location: 'Muar, Johor',
    );
    final updatedProjects = await repository.getProjects();
    final renamedProject = updatedProjects.singleWhere(
      (project) => project.projectName == 'Projek Integrasi Dikemas Kini',
    );
    expect(renamedProject.location, 'Muar, Johor');
    expect(renamedProject.plots, hasLength(3));
    final renamedPlotRows = await database.query(
      'plots',
      columns: ['project_name', 'location'],
      where: 'project_name = ?',
      whereArgs: ['Projek Integrasi Dikemas Kini'],
    );
    expect(renamedPlotRows, hasLength(3));
    expect(
      renamedPlotRows.every((row) => row['location'] == 'Muar, Johor'),
      isTrue,
    );

    await repository.deletePlot(secondPlotId);
    final deletedPlotRows = await database.query(
      'plots',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [secondPlotId],
    );
    expect(deletedPlotRows, isEmpty);
    final projectAfterPlotDeletion = (await repository.getProjects())
        .singleWhere(
          (project) => project.projectName == 'Projek Integrasi Dikemas Kini',
        );
    expect(projectAfterPlotDeletion.plots, hasLength(2));

    await repository.deleteProject('Projek Integrasi Dikemas Kini');
    final deletedRows = await database.query(
      'plots',
      columns: ['id'],
      where: 'id IN (?, ?, ?)',
      whereArgs: [plotId, secondPlotId, coconutPlotId],
    );
    expect(deletedRows, isEmpty);

    final syncChangeRows = await database.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['_sync_local_changed_at'],
    );
    expect(syncChangeRows, hasLength(1));
    expect(
      DateTime.tryParse(syncChangeRows.single['setting_value'] as String),
      isNotNull,
    );
  });

  test('switching account clears the previous user snapshot locally', () async {
    final database = await AppDatabase.instance.database;
    final repository = SqliteProjectRepository(AppDatabase.instance);
    final store = LocalSnapshotStore(AppDatabase.instance);

    await database.delete('plots');
    await repository.createProject(
      ProjectFormData(
        cropCode: 'pineapple',
        projectName: 'Projek Akaun Lama',
        location: 'Kota Bharu, Kelantan',
        plotName: 'Plot Lama',
        varieties: const [CropVariety(code: 'AC1', name: 'Moris')],
        raisedBedCount: 1,
        plantedAt: DateTime(2026, 9, 24),
      ),
    );
    expect(await store.hasUserData(), isTrue);

    final changedAt = await store.replaceWithEmptyDataForUser('user-b');

    expect(await store.hasUserData(), isFalse);
    final metadata = await store.getMetadata();
    expect(metadata.linkedUserId, 'user-b');
    expect(metadata.localChangedAt, changedAt);
    expect(metadata.lastSyncedLocalChangedAt, isNull);
    expect(metadata.lastRemoteUpdatedAt, isNull);
  });

  test(
    'new crops persist varieties, rows and tasks and appear on Home',
    () async {
      final database = await AppDatabase.instance.database;
      final projects = SqliteProjectRepository(AppDatabase.instance);
      final beds = SqliteRaisedBedRepository(AppDatabase.instance);
      final tasks = SqliteTaskRepository(AppDatabase.instance);
      final plotIds = <int>[];
      addTearDown(() async {
        for (final id in plotIds) {
          await projects.deletePlot(id);
        }
      });
      for (final code in ['banana', 'oil_palm', 'rubber_tree', 'ginger']) {
        final form = ProjectFormController(cropCode: code);
        addTearDown(form.dispose);
        final variety = form.availableVarieties.first;
        final id = await projects.createProject(
          ProjectFormData(
            cropCode: code,
            projectName: 'Projek $code',
            location: 'Johor',
            plotName: 'Plot $code',
            varieties: [variety],
            raisedBedCount: 2,
            plantedAt: DateTime(2026, 11, 3),
          ),
        );
        plotIds.add(id);
        await beds.saveRaisedBedDetails(
          plotId: id,
          bedNumber: 1,
          seedlingCount: 20,
          varieties: [variety],
        );
        final savedBeds = await beds.getRaisedBeds(id);
        expect(savedBeds, hasLength(2));
        expect(savedBeds.first.varieties, [variety]);
        await tasks.createTask(
          TaskFormData(
            plotId: id,
            cropCode: code,
            type: FarmTaskType.bedCleaning,
            includesAllRaisedBeds: true,
            raisedBedIds: {},
            scheduledAt: DateTime(2026, 11, 4, 8),
            notes: '',
          ),
        );
        final savedTasks = await tasks.getTasks(id);
        expect(savedTasks.single.cropCode, code);
        final available = await database.query(
          'crop_types',
          where: 'code = ?',
          whereArgs: [code],
        );
        expect(available.single['is_available'], 1);
      }
      final overviews = await SqliteHomeRepository(
        AppDatabase.instance,
      ).getPlotOverviews();
      for (final id in plotIds) {
        final overview = overviews.singleWhere((plot) => plot.plotId == id);
        expect(overview.totalPlants, 20);
        expect(overview.estimatedHarvestAt, isNotNull);
        expect(overview.daysToHarvest, isNotNull);
      }
    },
  );

  test(
    'rice and torch ginger survive version 16 upgrade with their tasks',
    () async {
      final database = await AppDatabase.instance.database;
      final projects = SqliteProjectRepository(AppDatabase.instance);
      final beds = SqliteRaisedBedRepository(AppDatabase.instance);
      final tasks = SqliteTaskRepository(AppDatabase.instance);
      final plotIds = <int>[];
      addTearDown(() async {
        for (final id in plotIds) {
          await projects.deletePlot(id);
        }
      });
      final cropIdsBefore = await database.query(
        'crop_types',
        columns: ['id', 'code'],
        orderBy: 'id',
      );
      for (final code in ['rice', 'torch_ginger']) {
        final form = ProjectFormController(cropCode: code);
        addTearDown(form.dispose);
        final variety = form.availableVarieties.first;
        final id = await projects.createProject(
          ProjectFormData(
            cropCode: code,
            projectName: 'Projek $code',
            location: 'Kedah',
            plotName: 'Plot $code',
            varieties: [variety],
            raisedBedCount: 2,
            plantedAt: DateTime(2026, 11, 3),
          ),
        );
        plotIds.add(id);
        final rows = await beds.getRaisedBeds(id);
        for (final type
            in code == 'rice'
                ? [FarmTaskType.ploughing, FarmTaskType.seedSowing]
                : [FarmTaskType.pruning, FarmTaskType.fruitHarvest]) {
          final saved = await tasks.createTask(
            TaskFormData(
              plotId: id,
              cropCode: code,
              type: type,
              includesAllRaisedBeds: false,
              raisedBedIds: {rows.first.id},
              scheduledAt: DateTime(2026, 11, 5, 8),
              notes: 'Nota $code',
            ),
          );
          expect(saved.type, type);
          expect(saved.raisedBedNumbers, [1]);
        }
        final home = await SqliteHomeRepository(
          AppDatabase.instance,
        ).getPlotOverviews();
        expect(home.any((plot) => plot.plotId == id), isTrue);
      }
      final plotsBefore = await database.query('plots', orderBy: 'id');
      await database.update(
        'crop_types',
        {'is_available': 0},
        where: 'code IN (?, ?)',
        whereArgs: ['rice', 'torch_ginger'],
      );
      await database.setVersion(16);
      await AppDatabase.instance.close();
      final upgraded = await AppDatabase.instance.database;
      expect(await upgraded.getVersion(), AppDatabase.databaseVersion);
      expect(await upgraded.query('plots', orderBy: 'id'), plotsBefore);
      expect(
        await upgraded.query(
          'crop_types',
          columns: ['id', 'code'],
          orderBy: 'id',
        ),
        cropIdsBefore,
      );
      final enabled = await upgraded.query(
        'crop_types',
        where: 'code IN (?, ?)',
        whereArgs: ['rice', 'torch_ginger'],
      );
      expect(enabled.map((row) => row['is_available']), everyElement(1));
      for (final id in plotIds) {
        final saved = await tasks.getTasks(id);
        expect(saved, hasLength(2));
        expect(saved.map((task) => task.raisedBedNumbers), everyElement([1]));
        expect(
          saved.first.raisedBedSummary(2),
          saved.first.cropCode == 'rice' ? 'Petak 1' : 'Baris 1',
        );
      }
    },
  );

  test('new task types survive saving, reloading and editing', () async {
    final projects = SqliteProjectRepository(AppDatabase.instance);
    final tasks = SqliteTaskRepository(AppDatabase.instance);
    final plotId = await projects.createProject(
      ProjectFormData(
        cropCode: 'banana',
        projectName: 'Projek Tugasan',
        location: 'Johor',
        plotName: 'Plot Tugasan',
        varieties: const [CropVariety(code: 'MP4', name: 'Berangan')],
        raisedBedCount: 1,
        plantedAt: DateTime(2026, 11, 3),
      ),
    );
    addTearDown(() => projects.deletePlot(plotId));
    const newTypes = [
      FarmTaskType.rubberTapping,
      FarmTaskType.irrigation,
      FarmTaskType.pruning,
      FarmTaskType.flowerInduction,
      FarmTaskType.bunchBagging,
      FarmTaskType.planting,
      FarmTaskType.bedPreparation,
      FarmTaskType.supportInstallation,
      FarmTaskType.mulching,
      FarmTaskType.manualPollination,
      FarmTaskType.fruitThinning,
      FarmTaskType.vineLifting,
    ];
    for (final type in newTypes) {
      final saved = await tasks.createTask(
        TaskFormData(
          plotId: plotId,
          cropCode: 'banana',
          type: type,
          includesAllRaisedBeds: true,
          raisedBedIds: {},
          scheduledAt: DateTime(2026, 11, 5, 8),
          notes: type.label,
        ),
      );
      expect(saved.type, type);
      await tasks.updateTask(
        taskId: saved.id,
        data: TaskFormData(
          plotId: plotId,
          cropCode: 'banana',
          type: type,
          includesAllRaisedBeds: true,
          raisedBedIds: {},
          scheduledAt: DateTime(2026, 11, 6, 9),
          notes: 'Dikemas kini',
        ),
      );
    }
    final reloaded = await tasks.getTasks(plotId);
    expect(reloaded.map((task) => task.type), unorderedEquals(newTypes));
    for (final task in reloaded) {
      expect(task.notes, 'Dikemas kini');
      expect(task.scheduledAt, DateTime(2026, 11, 6, 9));
    }
  });

  test(
    'version 15 upgrade enables new crops without replacing existing rows',
    () async {
      final database = await AppDatabase.instance.database;
      final projects = SqliteProjectRepository(AppDatabase.instance);
      final plotId = await projects.createProject(
        ProjectFormData(
          cropCode: 'pineapple',
          projectName: 'Projek Migrasi',
          location: 'Johor',
          plotName: 'Plot Kekal',
          varieties: const [CropVariety(code: 'AC1', name: 'Moris')],
          raisedBedCount: 2,
          plantedAt: DateTime(2026, 11, 3),
        ),
      );
      addTearDown(() => projects.deletePlot(plotId));
      final cropsBefore = await database.query(
        'crop_types',
        columns: ['id', 'code'],
        orderBy: 'id',
      );
      final plotBefore = await database.query(
        'plots',
        where: 'id = ?',
        whereArgs: [plotId],
      );
      await database.update(
        'crop_types',
        {'is_available': 0},
        where: 'code IN (?, ?, ?, ?)',
        whereArgs: ['banana', 'oil_palm', 'rubber_tree', 'ginger'],
      );
      await database.setVersion(15);
      await AppDatabase.instance.close();
      final upgraded = await AppDatabase.instance.database;
      expect(await upgraded.getVersion(), AppDatabase.databaseVersion);
      expect(
        await upgraded.query(
          'crop_types',
          columns: ['id', 'code'],
          orderBy: 'id',
        ),
        cropsBefore,
      );
      expect(
        await upgraded.query('plots', where: 'id = ?', whereArgs: [plotId]),
        plotBefore,
      );
      final available = await upgraded.query(
        'crop_types',
        where: 'is_available = 1',
      );
      expect(available.map((row) => row['code']).toSet(), {
        'pineapple',
        'coconut',
        'banana',
        'oil_palm',
        'rubber_tree',
        'ginger',
        'rice',
        'torch_ginger',
        'corn',
        'cassava',
        'sweet_potato',
        'durian',
        'watermelon',
        'rock_melon',
        'strawberry',
        'chilli',
        'cucumber',
        'eggplant',
      });
    },
  );
}
