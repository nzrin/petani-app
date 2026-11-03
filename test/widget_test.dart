import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:petani/shared/widgets/isometric_tractor.dart';
import 'package:petani/core/config/feature_flags.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/models/task_notification_record.dart';
import 'package:petani/core/repositories/notification_history_repository.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/controllers/home_controller.dart';
import 'package:petani/home/models/plot_overview.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/home/models/task_schedule_record.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/home/views/home_view.dart';
import 'package:petani/home/views/notification_history_view.dart';
import 'package:petani/home/views/task_schedule_day_view.dart';
import 'package:petani/home/views/task_schedule_view.dart';
import 'package:petani/home/views/upcoming_task_list_view.dart';
import 'package:petani/main.dart';
import 'package:petani/profile/models/notification_reminder_settings.dart';
import 'package:petani/profile/repositories/notification_settings_repository.dart';
import 'package:petani/profile/views/petani_support_card.dart';
import 'package:petani/profile/views/reminder_settings_view.dart';
import 'package:petani/project/controllers/project_controller.dart';
import 'package:petani/project/controllers/task_form_controller.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/models/task_control_product.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/plot_detail_view.dart';
import 'package:petani/project/views/project_detail_view.dart';
import 'package:petani/project/views/project_form_sheet.dart';
import 'package:petani/project/views/project_view.dart';
import 'package:petani/project/views/task_detail_view.dart';
import 'package:petani/project/views/task_target_picker_sheet.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/repositories/crop_selection_repository.dart';
import 'package:petani/shared/widgets/app_button.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    // Keep interaction tests deterministic while empty-state artwork loops.
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(
    () => binding.platformDispatcher.clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('notification history opens its related task detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const raisedBeds = [
      RaisedBedRecord(id: 1, plotId: 1, bedNumber: 1, seedlingCount: 100),
    ];
    final taskRepository = _MemoryTaskRepository(raisedBeds);
    await taskRepository.createTask(
      TaskFormData(
        plotId: 1,
        cropCode: 'pineapple',
        type: FarmTaskType.insectControl,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: DateTime(2026, 9, 24, 7, 30),
        notes: '',
      ),
    );
    final historyRepository = _MemoryNotificationHistoryRepository([
      TaskNotificationRecord(
        id: 7,
        taskId: 1,
        plotId: 1,
        type: FarmTaskType.insectControl,
        cropCode: 'pineapple',
        title: 'Kawalan Serangga',
        message: 'Peringatan mesra untuk tugasan anda.',
        receivedAt: DateTime(2026, 9, 24, 6, 30),
        taskScheduledAt: DateTime(2026, 9, 24, 7, 30),
        projectName: 'Projek Selatan',
        plotName: 'Plot A',
        isTaskAvailable: true,
        isRead: false,
      ),
      TaskNotificationRecord(
        id: 9,
        taskId: 1,
        plotId: 1,
        type: FarmTaskType.replanting,
        cropCode: 'pineapple',
        title: 'Menyulam',
        message: 'Mesej tersembunyi.',
        receivedAt: DateTime(2026, 9, 24, 5, 30),
        taskScheduledAt: DateTime(2026, 9, 24, 7),
        projectName: 'Projek Selatan',
        plotName: 'Plot A',
        isTaskAvailable: true,
        isRead: false,
      ),
      TaskNotificationRecord(
        id: 8,
        taskId: 1,
        plotId: 1,
        type: FarmTaskType.fertilizing,
        cropCode: 'pineapple',
        title: 'Membaja',
        message: 'Mesej ini juga tidak perlu kelihatan.',
        receivedAt: DateTime(2026, 9, 23, 17),
        taskScheduledAt: DateTime(2026, 9, 23, 18),
        projectName: 'Projek Utara',
        plotName: 'Plot B',
        isTaskAvailable: true,
        isRead: true,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: NotificationHistoryView(
          repository: historyRepository,
          taskRepository: taskRepository,
          raisedBedRepository: _MemoryRaisedBedRepository(raisedBeds),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Kawalan Serangga'), findsOneWidget);
    expect(find.text('Projek Selatan  ›  Plot A'), findsNWidgets(2));
    expect(find.text('24 September 2026'), findsOneWidget);
    expect(find.text('23 September 2026'), findsOneWidget);
    expect(find.text('6:30 pagi'), findsOneWidget);
    expect(find.text('Peringatan mesra untuk tugasan anda.'), findsNothing);
    expect(find.text('Mesej ini juga tidak perlu kelihatan.'), findsNothing);
    final unreadDot = find.byKey(
      const ValueKey<String>('notification-unread-dot-7'),
    );
    expect(unreadDot, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('notification-unread-dot-8')),
      findsNothing,
    );
    final notificationCell = find.byKey(
      const ValueKey<String>('notification-history-7'),
    );
    final secondNotificationCell = find.byKey(
      const ValueKey<String>('notification-history-9'),
    );
    final notificationImage = find.byKey(
      const ValueKey<String>('notification-task-image-7'),
    );
    expect(
      tester.getCenter(unreadDot).dx,
      greaterThan(tester.getTopRight(notificationImage).dx),
    );
    expect(
      tester.getCenter(notificationImage).dy,
      closeTo(tester.getCenter(notificationCell).dy, 0.6),
    );
    expect(
      tester.getBottomLeft(notificationCell).dy,
      closeTo(tester.getTopLeft(secondNotificationCell).dy, 0.6),
    );
    expect(
      (tester.widget<Container>(notificationCell).decoration as BoxDecoration)
          .borderRadius,
      const BorderRadius.vertical(top: Radius.circular(18)),
    );
    expect(
      (tester.widget<Container>(secondNotificationCell).decoration
              as BoxDecoration)
          .borderRadius,
      const BorderRadius.vertical(bottom: Radius.circular(18)),
    );
    expect(
      ((tester.widget<Container>(secondNotificationCell).decoration
                      as BoxDecoration)
                  .border
              as Border)
          .top,
      const BorderSide(color: Color(0xFFE5EAE7)),
    );
    await tester.tap(notificationCell);
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailView), findsOneWidget);
    expect(historyRepository.notifications.first.isRead, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('notification-unread-dot-7')),
      findsNothing,
    );

    await tester.drag(secondNotificationCell, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Menyulam'), findsNothing);
    expect(
      historyRepository.notifications.any((item) => item.id == 9),
      isFalse,
    );
    expect(find.text('Notifikasi telah dipadam.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification-settings-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification-options-sheet')), findsOneWidget);
    expect(find.byKey(const Key('notification-options-title')), findsOneWidget);
    final notificationOptionsTitle = tester.widget<Text>(
      find.byKey(const Key('notification-options-title')),
    );
    expect(notificationOptionsTitle.style?.fontSize, 24);
    expect(notificationOptionsTitle.style?.fontWeight, FontWeight.w700);
    expect(
      find.descendant(
        of: find.byKey(const Key('notification-options-sheet')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('notification-options-sheet')),
        matching: find.byType(Divider),
      ),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const Key('mark-all-notifications-read-button')),
    );
    await tester.pumpAndSettle();
    expect(
      historyRepository.notifications.every((item) => item.isRead),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey<String>('notification-unread-dot-9')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('notification-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-all-notifications-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-confirmation-sheet')), findsOneWidget);
    expect(historyRepository.notifications, isNotEmpty);
    await tester.tap(
      find.byKey(const Key('app-confirmation-sheet-confirm-button')),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(historyRepository.notifications, isEmpty);
    expect(find.text('Tiada Notifikasi'), findsOneWidget);
  });

  test('task form keeps its own time when the date changes', () {
    final controller = TaskFormController(
      plotId: 1,
      cropCode: 'pineapple',
      raisedBeds: const [],
      initialDate: DateTime(2026, 10, 24),
    );
    addTearDown(controller.dispose);

    expect(controller.scheduledAt, DateTime(2026, 10, 24, 7, 30));
    controller.setScheduledTime(hour: 14, minute: 45);
    controller.setScheduledAt(DateTime(2026, 10, 26));

    expect(controller.scheduledAt, DateTime(2026, 10, 26, 14, 45));
  });

  test('crop row terminology follows the selected crop', () {
    expect(CropRowTerminology.forCropCode('pineapple').title, 'Batas');
    expect(CropRowTerminology.forCropCode('coconut').title, 'Baris');
    expect(FarmTaskType.bedCleaning.labelForCrop('coconut'), 'Mencuci Baris');
    expect(
      PlotTaskRecord(
        id: 1,
        plotId: 1,
        type: FarmTaskType.bedCleaning,
        scheduledAt: DateTime(2026, 9, 24),
        notes: '',
        raisedBedNumbers: [1, 3],
        isCompleted: false,
        completedAt: null,
        cropCode: 'coconut',
      ).raisedBedSummary(8),
      '2 baris dipilih',
    );
  });

  testWidgets('daily schedule adds a task using the viewed date and refreshes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime(2030, 2, 14, 18, 45);
    const raisedBeds = [
      RaisedBedRecord(id: 1, plotId: 1, bedNumber: 1, seedlingCount: 100),
    ];
    const project = ProjectRecord(
      key: 'jadual',
      projectName: 'Projek Jadual',
      location: 'Johor',
      cropTypes: [ProjectCropType(code: 'pineapple', name: 'Nanas')],
      plots: [
        PlotRecord(
          id: 1,
          name: 'Plot A',
          cropCode: 'pineapple',
          cropName: 'Nanas',
          imagePath: 'assets/images/seeds/pineapple_fruit.png',
          varieties: [CropVariety(code: 'AC1', name: 'Moris')],
          raisedBedCount: 1,
          plantedAt: null,
        ),
      ],
    );
    final tasks = _MemoryTaskRepository(raisedBeds);
    final home = _MemoryHomeRepository([]);
    var refreshed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => AppToastHost(child: child!),
        home: TaskScheduleDayView(
          date: date,
          repository: home,
          taskRepository: tasks,
          projectRepository: _MemoryProjectRepository(projects: [project]),
          raisedBedRepository: _MemoryRaisedBedRepository(raisedBeds),
          onScheduleChanged: () async {
            refreshed++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tiada Tugasan'), findsOneWidget);
    final add = find.byKey(const Key('add-schedule-day-task-button'));
    await tester.tap(add);
    await tester.pumpAndSettle();
    // Dismissing project selection creates no task and allows another attempt.
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(tasks.tasks, isEmpty);
    expect(tester.widget<AppButton>(add).onPressed, isNotNull);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-target-project-jadual')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task-target-continue-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-target-plot-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task-target-continue-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-type-fertilizing')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('14 Februari 2030'), findsWidgets);
    expect(find.text('7:30 pagi'), findsOneWidget);
    final loadCount = home.scheduleLoadCount;
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    expect(tasks.tasks.single.scheduledAt, DateTime(2030, 2, 14, 7, 30));
    expect(tasks.tasks.single.plotId, 1);
    expect(tasks.tasks.single.type, FarmTaskType.fertilizing);
    expect(home.scheduleLoadCount, greaterThan(loadCount));
    expect(refreshed, 1);
    expect(tester.widget<AppButton>(add).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily schedule uses a compact time axis and opens task detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scheduledAt = DateTime(2026, 9, 24, 7, 30);
    const raisedBeds = [
      RaisedBedRecord(id: 1, plotId: 1, bedNumber: 1, seedlingCount: 100),
    ];
    final taskRepository = _MemoryTaskRepository(raisedBeds);
    await taskRepository.createTask(
      TaskFormData(
        plotId: 1,
        type: FarmTaskType.bedCleaning,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: scheduledAt,
        notes: '',
      ),
    );
    await taskRepository.createTask(
      TaskFormData(
        plotId: 1,
        type: FarmTaskType.fertilizing,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: scheduledAt,
        notes: '',
      ),
    );
    final homeRepository = _MemoryHomeRepository([
      UpcomingTaskRecord(
        id: 1,
        plotId: 1,
        type: FarmTaskType.bedCleaning,
        cropCode: 'pineapple',
        cropName: 'Nanas',
        projectName: 'Projek Selatan',
        plotName: 'Plot A',
        location: 'Pontian, Johor',
        scheduledAt: scheduledAt,
      ),
      UpcomingTaskRecord(
        id: 2,
        plotId: 1,
        type: FarmTaskType.fertilizing,
        cropCode: 'pineapple',
        cropName: 'Nanas',
        projectName: 'Projek Selatan',
        plotName: 'Plot A',
        location: 'Pontian, Johor',
        scheduledAt: scheduledAt,
      ),
    ]);
    var scheduleRefreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: TaskScheduleDayView(
          date: scheduledAt,
          repository: homeRepository,
          taskRepository: taskRepository,
          raisedBedRepository: _MemoryRaisedBedRepository(raisedBeds),
          onScheduleChanged: () async {
            scheduleRefreshCount++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('24 September 2026'), findsOneWidget);
    expect(find.text('MASA'), findsOneWidget);
    expect(find.text('TUGASAN'), findsOneWidget);
    expect(find.text('1 tugasan'), findsNothing);
    expect(find.byKey(const Key('task-schedule-selected-date')), findsNothing);
    expect(find.text('7:30'), findsOneWidget);
    expect(find.text('PAGI'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('task-schedule-time-dot-2')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('task-schedule-time-1')))
          .width,
      31,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('task-schedule-day-task-1')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailView), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('complete-task-button')));
    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('app-confirmation-sheet-confirm-button')),
    );
    await tester.pumpAndSettle();
    expect(scheduleRefreshCount, 1);
  });

  testWidgets('home lists database-backed upcoming tasks with search', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final today = DateTime.now();
    final repository = _MemoryHomeRepository([
      UpcomingTaskRecord(
        id: 1,
        plotId: 1,
        type: FarmTaskType.insectControl,
        cropCode: 'pineapple',
        cropName: 'Nanas',
        projectName: 'Projek Selatan',
        plotName: 'Plot A',
        location: 'Pontian, Johor',
        scheduledAt: today,
      ),
      UpcomingTaskRecord(
        id: 2,
        plotId: 2,
        type: FarmTaskType.bedCleaning,
        cropCode: 'coconut',
        cropName: 'Kelapa',
        projectName: 'Projek Timur',
        plotName: 'Plot Kelapa',
        location: 'Bachok, Kelantan',
        scheduledAt: today.add(const Duration(days: 1)),
      ),
      UpcomingTaskRecord(
        id: 3,
        plotId: 3,
        type: FarmTaskType.fertilizing,
        cropCode: 'pineapple',
        cropName: 'Nanas',
        projectName: 'Projek Tengah',
        plotName: 'Plot Baja',
        location: 'Temerloh, Pahang',
        scheduledAt: today.add(const Duration(days: 2)),
      ),
      UpcomingTaskRecord(
        id: 4,
        plotId: 4,
        type: FarmTaskType.weedControl,
        cropCode: 'pineapple',
        cropName: 'Nanas',
        projectName: 'Projek Utara',
        plotName: 'Plot D',
        location: 'Sik, Kedah',
        scheduledAt: today.add(const Duration(days: 3)),
      ),
    ]);
    const upcomingTaskRaisedBeds = [
      RaisedBedRecord(id: 1, plotId: 1, bedNumber: 1, seedlingCount: 100),
    ];
    final upcomingTaskRepository = _MemoryTaskRepository(
      upcomingTaskRaisedBeds,
    );
    await upcomingTaskRepository.createTask(
      TaskFormData(
        plotId: 1,
        type: FarmTaskType.insectControl,
        includesAllRaisedBeds: true,
        raisedBedIds: const {},
        scheduledAt: today,
        notes: '',
      ),
    );
    final controller = HomeController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadUpcomingTasks();
    var addPlotRequested = false;
    var addTaskRequested = false;
    final notificationHistoryRepository = _MemoryNotificationHistoryRepository([
      TaskNotificationRecord(
        id: 10,
        taskId: 1,
        plotId: 1,
        type: FarmTaskType.insectControl,
        cropCode: 'pineapple',
        title: 'Kawalan Serangga',
        message: 'Peringatan',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        taskScheduledAt: DateTime.now(),
        projectName: 'Projek Selatan',
        plotName: 'Plot A',
        isTaskAvailable: true,
        isRead: false,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeView(
            controller: controller,
            onAddPlot: () => addPlotRequested = true,
            onAddTask: () => addTaskRequested = true,
            taskRepository: upcomingTaskRepository,
            raisedBedRepository: _MemoryRaisedBedRepository(
              upcomingTaskRaisedBeds,
            ),
            notificationHistoryRepository: notificationHistoryRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final overviewStack = find.byKey(const Key('farm-overview-stack'));
    expect(overviewStack, findsOneWidget);
    final pineappleOverview = find.byKey(const Key('plot-overview-card-101'));
    final coconutOverview = find.byKey(const Key('plot-overview-card-102'));
    final thirdOverview = find.byKey(const Key('plot-overview-card-103'));
    final incomingOverview = find.byKey(const Key('plot-overview-card-104'));
    final gradientSignatures = List.generate(5, (index) {
      final plotId = 101 + index;
      final background = tester.widget<Container>(
        find.byKey(ValueKey<String>('plot-overview-background-$plotId')),
      );
      final decoration = background.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      return gradient.colors.map((color) => color.toString()).join(',');
    });
    expect(gradientSignatures.toSet(), hasLength(5));
    expect(
      tester.getRect(coconutOverview).width,
      lessThan(tester.getRect(pineappleOverview).width),
    );
    expect(
      tester.getRect(thirdOverview).width,
      lessThan(tester.getRect(coconutOverview).width),
    );
    expect(
      tester.getTopLeft(pineappleOverview).dy,
      lessThan(tester.getTopLeft(coconutOverview).dy),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));
    final incomingOpacity = tester.widget<Opacity>(
      find.ancestor(of: incomingOverview, matching: find.byType(Opacity)).first,
    );
    expect(incomingOpacity.opacity, greaterThan(0.5));
    await tester.pump(const Duration(milliseconds: 100));
    final pineappleTopWhileHeld = tester.getTopLeft(pineappleOverview).dy;
    final coconutTopWhileHeld = tester.getTopLeft(coconutOverview).dy;
    final holdGesture = await tester.startGesture(
      tester.getCenter(overviewStack),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.getTopLeft(pineappleOverview).dy,
      closeTo(pineappleTopWhileHeld, 0.1),
    );
    expect(
      tester.getTopLeft(coconutOverview).dy,
      closeTo(coconutTopWhileHeld, 0.1),
    );
    await holdGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(
      tester.getTopLeft(coconutOverview).dy,
      lessThan(tester.getTopLeft(pineappleOverview).dy),
    );

    await tester.fling(overviewStack, const Offset(0, 220), 900);
    await tester.pump(const Duration(milliseconds: 650));
    expect(
      tester.getTopLeft(coconutOverview).dy,
      lessThan(tester.getTopLeft(pineappleOverview).dy),
    );

    await tester.fling(overviewStack, const Offset(0, -220), 900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(
      tester.getTopLeft(thirdOverview).dy,
      lessThan(tester.getTopLeft(coconutOverview).dy),
    );

    await tester.tap(find.byKey(const Key('quick-add-plot-button')));
    expect(addPlotRequested, isTrue);
    expect(find.byType(Badge), findsNothing);
    expect(find.byKey(const Key('home-notification-button')), findsOneWidget);
    expect(
      find.byKey(const Key('home-notification-speaker-icon')),
      findsOneWidget,
    );
    final homeNotificationButton = tester.widget<IconButton>(
      find.byKey(const Key('home-notification-button')),
    );
    expect(
      homeNotificationButton.style?.backgroundColor?.resolve({}),
      AppColors.green,
    );
    final speakerIcon = tester.widget<Image>(
      find.byKey(const Key('home-notification-speaker-icon')),
    );
    expect(speakerIcon.color, Colors.white);
    expect(
      find.byKey(const Key('home-notification-unread-dot')),
      findsOneWidget,
    );
    final quickAddTaskLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('quick-add-task-button')),
        matching: find.byType(Text),
        skipOffstage: false,
      ),
    );
    expect(quickAddTaskLabel.data, 'TAMBAH\nTUGASAN');
    expect(quickAddTaskLabel.style?.color, AppColors.green);
    expect(quickAddTaskLabel.style?.fontWeight, FontWeight.w900);
    await tester.tap(find.byKey(const Key('quick-add-task-button')));
    expect(addTaskRequested, isTrue);
    expect(find.text('Kawalan Serangga'), findsOneWidget);
    expect(find.text('Mencuci Baris'), findsOneWidget);
    expect(find.text('Membaja'), findsOneWidget);
    expect(find.text('Kawalan Rumpai'), findsNothing);
    final firstUpcomingTask = find.byKey(
      const ValueKey<String>('upcoming-task-1'),
    );
    final secondUpcomingTask = find.byKey(
      const ValueKey<String>('upcoming-task-2'),
    );
    final thirdUpcomingTask = find.byKey(
      const ValueKey<String>('upcoming-task-3'),
    );
    expect(
      tester.getBottomLeft(firstUpcomingTask).dy,
      tester.getTopLeft(secondUpcomingTask).dy,
    );
    expect(
      tester.getBottomLeft(secondUpcomingTask).dy,
      tester.getTopLeft(thirdUpcomingTask).dy,
    );
    expect(
      (tester.widget<Container>(firstUpcomingTask).decoration as BoxDecoration)
          .borderRadius,
      const BorderRadius.vertical(top: Radius.circular(18)),
    );
    expect(
      (tester.widget<Container>(secondUpcomingTask).decoration as BoxDecoration)
          .borderRadius,
      BorderRadius.zero,
    );
    expect(
      (tester.widget<Container>(thirdUpcomingTask).decoration as BoxDecoration)
          .borderRadius,
      const BorderRadius.vertical(bottom: Radius.circular(18)),
    );

    await tester.tap(firstUpcomingTask);
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailView), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task-schedule-button')));
    await tester.pumpAndSettle();
    expect(find.byType(TaskScheduleView), findsOneWidget);
    expect(find.text('Jadual Tugasan'), findsOneWidget);
    expect(find.byKey(const Key('task-month-calendar')), findsOneWidget);
    expect(repository.scheduleLoadCount, 1);
    expect(
      find.byKey(const ValueKey<String>('task-schedule-month-task-1')),
      findsOneWidget,
    );
    expect(find.byType(TaskScheduleDayView), findsNothing);
    await tester.tap(
      find.byKey(
        ValueKey<String>(
          'task-schedule-day-${today.year}-${today.month}-${today.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TaskScheduleDayView), findsOneWidget);
    expect(repository.scheduleLoadCount, 2);
    expect(find.byKey(const Key('task-schedule-day-list')), findsOneWidget);
    expect(find.text('MASA'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('task-schedule-time-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('task-schedule-time-dot-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('task-schedule-day-task-1')),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TaskScheduleView), findsOneWidget);
    expect(repository.scheduleLoadCount, 3);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('view-all-upcoming-tasks-button')));
    await tester.pumpAndSettle();
    expect(find.byType(UpcomingTaskListView), findsOneWidget);
    expect(find.byKey(const Key('upcoming-task-search-field')), findsOneWidget);
    expect(find.text('Kawalan Rumpai'), findsOneWidget);
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey<String>('upcoming-task-1')),
                  )
                  .decoration
              as BoxDecoration)
          .borderRadius,
      const BorderRadius.vertical(top: Radius.circular(18)),
    );
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey<String>('upcoming-task-4')),
                  )
                  .decoration
              as BoxDecoration)
          .borderRadius,
      const BorderRadius.vertical(bottom: Radius.circular(18)),
    );

    await tester.tap(find.byKey(const ValueKey<String>('upcoming-task-1')));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailView), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(UpcomingTaskListView), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('upcoming-task-search-field')),
      'Kelantan',
    );
    await tester.pump();
    expect(find.text('Mencuci Baris'), findsOneWidget);
    expect(find.text('Kawalan Serangga'), findsNothing);
    expect(find.text('Membaja'), findsNothing);
    expect(find.text('Kawalan Rumpai'), findsNothing);
  });

  testWidgets('welcome flow opens crop picker and enters main app', (
    tester,
  ) async {
    expect(
      CropSelectionController.cropOptions.map((crop) => crop.imagePath),
      everyElement(startsWith('assets/images/crops/')),
    );
    expect(
      CropSelectionController.cropOptions
          .firstWhere((crop) => crop.code == 'coconut')
          .isAvailable,
      isTrue,
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    try {
      final database = await AppDatabase.instance.database;
      await database.delete(
        'app_settings',
        where: 'setting_key IN (?, ?)',
        whereArgs: [
          'profile_support_card_hidden',
          'profile_support_card_viewed',
        ],
      );
    } catch (_) {
      // Widget-only runs may not initialize the SQLite FFI database.
    }

    await tester.pumpWidget(
      PetaniApp(
        cropSelectionRepository: _MemoryCropSelectionRepository(),
        projectRepository: _MemoryProjectRepository(),
        homeRepository: _MemoryHomeRepository([], plotOverviews: const []),
        showSplash: false,
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.textTheme.bodyMedium?.fontFamily, 'ProductSans');

    expect(find.text('Tanaman Lebih Tersusun'), findsOneWidget);
    expect(find.text('Mula Sekarang'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mula-sekarang-button')));
    await tester.pumpAndSettle();

    expect(find.text('Senarai Tanaman'), findsOneWidget);
    expect(find.text('Nanas'), findsOneWidget);
    expect(find.text('Teruskan'), findsOneWidget);
    expect(find.byKey(const Key('crop-grid')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('crop-search-field')), 'Halia');
    await tester.pumpAndSettle();
    final searchEditable = find.descendant(
      of: find.byKey(const Key('crop-search-field')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(searchEditable).focusNode.hasFocus,
      isTrue,
    );

    await tester.tap(find.text('Senarai Tanaman'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(searchEditable).focusNode.hasFocus,
      isFalse,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('crop-grid')),
        matching: find.text('Halia'),
      ),
      findsOneWidget,
    );
    expect(find.text('Nanas'), findsNothing);

    await tester.enterText(find.byKey(const Key('crop-search-field')), 'Nanas');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final nanasTile = find.byKey(const ValueKey<String>('crop-tile-Nanas'));
    await tester.ensureVisible(nanasTile);
    await tester.pumpAndSettle();
    await tester.tap(nanasTile);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('teruskan-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Namakan projek anda'), findsOneWidget);
    expect(find.text('Langkah 1 daripada 4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('project-form-leading-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.byKey(const Key('chatbot-floating-button')), findsOneWidget);
    final chatbotFloatingIcon = tester.widget<Image>(
      find.byKey(const Key('chatbot-floating-icon')),
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('chatbot-floating-icon')),
        matching: find.byType(ScaleTransition),
      ),
      findsAtLeastNWidgets(1),
    );
    expect(
      (chatbotFloatingIcon.image as AssetImage).assetName,
      'assets/images/icon_head_1000.png',
    );
    expect(find.byKey(const Key('quick-add-task-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chatbot-floating-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatbot-view')), findsOneWidget);
    expect(
      find.text('Apa yang boleh saya bantu anda hari ini?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chatbot-close-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('quick-add-task-button')), findsOneWidget);
    expect(find.text('Utama'), findsOneWidget);
    expect(find.text('Projek'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Tiada data tanaman untuk dipaparkan.'), findsNothing);
    expect(find.byKey(const Key('farm-overview-empty')), findsNothing);
    expect(
      tester.getTopLeft(find.text('Tindakan Pantas')).dy -
          tester.getBottomLeft(find.text('Petani Moden')).dy,
      lessThan(60),
    );
    expect(
      find.byKey(const Key('view-all-upcoming-tasks-button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('empty-upcoming-task-tractor')),
      findsOneWidget,
    );
    expect(
      tester.getCenter(find.byKey(const Key('empty-upcoming-tasks'))).dx,
      closeTo(195, 1),
    );
    final emptyUpcomingTitle = tester.widget<Text>(find.text('Tiada Tugasan'));
    final emptyUpcomingDescription = tester.widget<Text>(
      find.text('Tugasan akan datang akan dipaparkan di sini.'),
    );
    final homeTheme = Theme.of(tester.element(find.text('Tiada Tugasan')));
    expect(
      emptyUpcomingTitle.style?.fontSize,
      homeTheme.textTheme.titleLarge?.fontSize,
    );
    expect(
      emptyUpcomingTitle.style?.fontWeight,
      homeTheme.textTheme.titleLarge?.fontWeight,
    );
    expect(
      emptyUpcomingDescription.style?.fontSize,
      homeTheme.textTheme.bodyMedium?.fontSize,
    );
    expect(
      emptyUpcomingDescription.style?.fontWeight,
      homeTheme.textTheme.bodyMedium?.fontWeight,
    );

    await tester.tap(find.text('Projek'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Projek'), findsNWidgets(2));
    expect(find.byKey(const Key('empty-project-tractor')), findsOneWidget);
    expect(
      tester.widget(find.byKey(const Key('empty-project-tractor'))),
      isA<IsometricTractor>(),
    );
    expect(
      tester
          .widget<FloatingActionButton>(
            find.byKey(const Key('add-project-button')),
          )
          .shape,
      isA<CircleBorder>(),
    );
    final selectedPill = tester.widget<DecoratedBox>(
      find.byKey(const Key('selected-navigation-pill')),
    );
    final selectedPillDecoration = selectedPill.decoration as BoxDecoration;
    expect(selectedPillDecoration.boxShadow, isNotEmpty);

    await tester.tap(find.byKey(const Key('add-project-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Senarai Tanaman'), findsOneWidget);
    await tester.tap(find.byKey(const Key('teruskan-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Namakan projek anda'), findsOneWidget);
    await tester.tap(find.byKey(const Key('project-form-leading-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Laporan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Laporan'), findsWidgets);
    expect(find.text('Aktiviti Tugasan'), findsOneWidget);
    expect(find.text('Jumlah Pokok'), findsOneWidget);
    expect(find.text('Tugasan Selesai'), findsOneWidget);
    expect(find.text('Jumlah Projek'), findsOneWidget);
    expect(find.text('Jumlah Plot'), findsOneWidget);
    expect(find.text('Belum Selesai'), findsWidgets);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Lebih Masa'), findsOneWidget);
    expect(find.byKey(const Key('task-statistics-chart')), findsOneWidget);
    expect(find.text('Trend Tugasan'), findsOneWidget);
    expect(find.text('Rekod Tanaman'), findsOneWidget);
    expect(find.byKey(const Key('monthly-task-wave-chart')), findsOneWidget);
    expect(find.byKey(const Key('monthly-plant-bar-chart')), findsOneWidget);
    final pendingStatisticsCard = tester.widget<Container>(
      find.byKey(const Key('task-statistics-card')),
    );
    expect(
      ((pendingStatisticsCard.decoration as BoxDecoration).gradient
              as LinearGradient)
          .colors
          .first,
      AppColors.yellow,
    );
    await tester.tap(find.byKey(const ValueKey<String>('task-status-overdue')));
    await tester.pump();
    final overdueStatisticsCard = tester.widget<Container>(
      find.byKey(const Key('task-statistics-card')),
    );
    expect(
      ((overdueStatisticsCard.decoration as BoxDecoration).gradient
              as LinearGradient)
          .colors
          .first,
      const Color(0xFFC62828),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('task-status-completed')),
    );
    await tester.pump();
    final completedStatisticsCard = tester.widget<Container>(
      find.byKey(const Key('task-statistics-card')),
    );
    expect(
      ((completedStatisticsCard.decoration as BoxDecoration).gradient
              as LinearGradient)
          .colors
          .first,
      AppColors.primaryAction,
    );

    await tester.tap(find.text('Profil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Profil'), findsWidgets);
    expect(find.byKey(const Key('profile-login-card')), findsOneWidget);
    expect(find.byKey(const Key('profile-login-illustration')), findsNothing);
    expect(find.byKey(const Key('profile-login-title')), findsOneWidget);
    expect(find.byKey(const Key('profile-why-login-button')), findsOneWidget);
    expect(find.byKey(const Key('profile-login-button')), findsOneWidget);
    if (FeatureFlags.showPetaniSupportSection) {
      expect(find.textContaining('Dari Petani Kepada Petani'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('petani-support-indicator')),
        findsOneWidget,
      );

      expect(
        tester
            .widget<PetaniSupportCard>(find.byType(PetaniSupportCard))
            .initiallyHidden,
        isTrue,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('compact-petani-support-card')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(
        find.byKey(const ValueKey<String>('compact-petani-support-card')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(
        find.byKey(const ValueKey<String>('petani-support-indicator')),
        findsNothing,
      );
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(
        find.byKey(const ValueKey<String>('petani-support-indicator')),
        findsNothing,
      );
    } else {
      expect(find.textContaining('Dari Petani Kepada Petani'), findsNothing);
      expect(find.byType(PetaniSupportCard), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('petani-support-indicator')),
        findsNothing,
      );
    }
    expect(find.text('Tetapan Umum'), findsOneWidget);
    expect(find.text('Log Keluar'), findsNothing);
    expect(find.text('Padam Akaun'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('danger-zone-action-Log Keluar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('danger-zone-action-Padam Akaun')),
      findsNothing,
    );
    expect(find.text('Versi'), findsOneWidget);
  });

  testWidgets('project form progresses and opens the reusable date sheet', (
    tester,
  ) async {
    // This test measures the form's intermediate animated height.
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ProjectFormSheet(
                      suggestions: ProjectFormSuggestions(
                        existingProjects: [
                          const ExistingProjectSuggestion(
                            name: 'Projek Sedia Ada',
                            location: 'Pontian, Johor',
                            plotNames: ['Plot Lama'],
                          ),
                          ...List.generate(
                            24,
                            (index) => ExistingProjectSuggestion(
                              name: 'Projek Ujian ${index + 1}',
                              location: 'Lokasi ${index + 1}',
                            ),
                          ),
                        ],
                        locations: const ['Pontian, Johor'],
                      ),
                    ),
                  ),
                  child: const Text('Buka Borang'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Buka Borang'));
    await tester.pumpAndSettle();

    final compactSheetHeight = tester
        .getSize(find.byKey(const Key('project-form-sheet-surface')))
        .height;
    expect(find.text('Projek Sedia Ada'), findsOneWidget);
    final projectSuggestionList = tester.widget<ListView>(
      find.byKey(
        const ValueKey<String>('project-form-Nama Projek-suggestions'),
      ),
    );
    expect(projectSuggestionList.scrollDirection, Axis.horizontal);
    expect(
      (((projectSuggestionList.childrenDelegate as SliverChildBuilderDelegate)
                      .childCount ??
                  0) +
              1) ~/
          2,
      10,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Projek')),
      'zzzzzzzz',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('project-form-Nama Projek-suggestions'),
      ),
      findsNothing,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('project-form-sheet-surface')))
          .height,
      lessThan(compactSheetHeight),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Projek')),
      'Projek Sedai Ada',
    );
    await tester.pumpAndSettle();
    expect(find.text('Projek Sedia Ada'), findsOneWidget);
    final filteredSuggestionList = tester.widget<ListView>(
      find.byKey(
        const ValueKey<String>('project-form-Nama Projek-suggestions'),
      ),
    );
    expect(
      (((filteredSuggestionList.childrenDelegate as SliverChildBuilderDelegate)
                      .childCount ??
                  0) +
              1) ~/
          2,
      1,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Projek')),
      'Projek Sedia Ada',
    );
    await tester.pump();
    expect(find.text('Langkah 1 daripada 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('project-form-continue-button')));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 2 daripada 3'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('project-form-Nama Plot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('project-form-Nama Plot-suggestions')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Plot')),
      '  plot   lama ',
    );
    await tester.pump();
    expect(
      find.text('Nama plot ini sudah digunakan dalam projek ini.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('project-form-continue-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Plot')),
      'Plot Baharu',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('project-form-continue-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('project-form-leading-button')));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 1 daripada 3'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Projek')),
      'Projek Nanas',
    );
    await tester.pump();
    expect(find.text('Langkah 1 daripada 4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('project-form-continue-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Lokasi')),
      'Pontian, Johor',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('project-form-continue-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Plot')),
      'Plot A',
    );
    tester.binding.focusManager.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final stepThreeSheetHeight = tester
        .getSize(find.byKey(const Key('project-form-sheet-surface')))
        .height;
    await tester.tap(find.byKey(const Key('project-form-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('Lengkapkan tanaman anda'), findsOneWidget);
    expect(find.text('AC1 - Moris'), findsOneWidget);
    expect(find.text('Batas'), findsOneWidget);
    expect(find.byKey(const Key('raised-bed-slider')), findsOneWidget);
    final fullSheetHeight = tester
        .getSize(find.byKey(const Key('project-form-sheet-surface')))
        .height;
    expect(fullSheetHeight, greaterThan(stepThreeSheetHeight));

    await tester.tap(find.byKey(const Key('project-form-leading-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 170));
    final shrinkingSheetHeight = tester
        .getSize(find.byKey(const Key('project-form-sheet-surface')))
        .height;
    expect(shrinkingSheetHeight, lessThan(fullSheetHeight));
    expect(shrinkingSheetHeight, greaterThan(stepThreeSheetHeight));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const Key('project-form-sheet-surface')))
          .height,
      stepThreeSheetHeight,
    );

    await tester.tap(find.byKey(const Key('project-form-continue-button')));
    await tester.pumpAndSettle();

    final raisedBedSlider = tester.widget<Slider>(
      find.byKey(const Key('raised-bed-slider')),
    );
    expect(raisedBedSlider.min, 1);
    expect(raisedBedSlider.max, 50);
    expect(raisedBedSlider.divisions, isNull);
    expect(raisedBedSlider.padding, const EdgeInsets.symmetric(horizontal: 15));

    final ac1Chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'AC1 - Moris'),
    );
    expect(ac1Chip.selected, isFalse);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('project-form-continue-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(
      find.widgetWithText(ChoiceChip, 'AC5 - Josapine'),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'AC5 - Josapine'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'AC1 - Moris'))
          .selected,
      isFalse,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'AC5 - Josapine'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('project-form-continue-button')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.ensureVisible(
      find.byKey(const Key('open-planted-date-button')),
    );
    await tester.tap(find.byKey(const Key('open-planted-date-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('planted-date-picker')), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Sahkan Tarikh'), findsOneWidget);
  });

  testWidgets('quick add plot requires an existing project first', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showModalBottomSheet<ProjectFormData>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ProjectFormSheet(
                  cropCode: 'pineapple',
                  requireExistingProject: true,
                  suggestions: ProjectFormSuggestions(
                    existingProjects: [
                      ExistingProjectSuggestion(
                        name: 'Projek Kebun Utama',
                        location: 'Pontian, Johor',
                        plotNames: ['Plot Lama'],
                      ),
                    ],
                  ),
                ),
              ),
              child: const Text('Tambah Plot Pantas'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tambah Plot Pantas'));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 1 daripada 3'), findsOneWidget);
    expect(find.text('Pilih projek anda'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('project-form-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Projek')),
      'Projek Tidak Wujud',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('project-form-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Projek')),
      '',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'project-form-Nama Projek-suggestion-Projek Kebun Utama',
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('project-form-continue-button')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('project-form-continue-button')));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 2 daripada 3'), findsOneWidget);
    expect(find.text('Namakan plot tanaman'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey<String>('project-form-Nama Plot')),
      'Plot Baharu',
    );
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('project-form-continue-button')));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 3 daripada 3'), findsOneWidget);
    expect(find.text('Lengkapkan tanaman anda'), findsOneWidget);
    expect(find.text('Simpan Plot'), findsOneWidget);
  });

  testWidgets('quick add task selects a project before selecting its plot', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const project = ProjectRecord(
      key: 'projek-utama',
      projectName: 'Projek Utama',
      location: 'Pontian, Johor',
      cropTypes: [ProjectCropType(code: 'pineapple', name: 'Nanas')],
      plots: [
        PlotRecord(
          id: 11,
          name: 'Plot A',
          cropCode: 'pineapple',
          cropName: 'Nanas',
          imagePath: 'assets/images/crops/pineapple.png',
          varieties: [CropVariety(code: 'AC1', name: 'Moris')],
          raisedBedCount: 12,
          plantedAt: null,
        ),
      ],
    );
    PlotRecord? selectedPlot;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                selectedPlot = await showTaskTargetPickerSheet(
                  context: context,
                  projects: const [project],
                );
              },
              child: const Text('Mulakan Tambah Tugasan'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mulakan Tambah Tugasan'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-target-picker-sheet')), findsNothing);
    expect(selectedPlot, isNull);
    await tester.tap(find.text('Mulakan Tambah Tugasan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-target-picker-sheet')), findsOneWidget);
    expect(find.text('Langkah 1 daripada 2'), findsOneWidget);
    expect(find.text('Pilih Projek'), findsOneWidget);
    expect(find.text('Projek Utama'), findsOneWidget);
    expect(find.text('Pontian, Johor'), findsNothing);
    expect(find.text('1 plot'), findsOneWidget);
    final projectGrid = tester.widget<GridView>(
      find.byKey(const Key('task-target-selection-grid')),
    );
    expect(
      projectGrid.gridDelegate,
      isA<SliverGridDelegateWithFixedCrossAxisCount>().having(
        (delegate) => delegate.crossAxisCount,
        'crossAxisCount',
        2,
      ),
    );
    expect(
      (projectGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .mainAxisExtent,
      80,
    );
    expect(
      tester.widget<Text>(find.text('Projek Utama')).textAlign,
      TextAlign.left,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('task-target-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('task-target-project-projek-utama')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('task-target-continue-button')));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 2 daripada 2'), findsOneWidget);
    expect(find.text('Pilih Plot'), findsOneWidget);
    expect(find.text('Plot A'), findsOneWidget);
    expect(find.text('Nanas'), findsOneWidget);
    expect(find.text('12 batas'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('task-target-plot-11')),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == Colors.white;
        }),
      ),
      findsNothing,
    );
    final plotGrid = tester.widget<GridView>(
      find.byKey(const Key('task-target-selection-grid')),
    );
    expect(
      plotGrid.gridDelegate,
      isA<SliverGridDelegateWithFixedCrossAxisCount>().having(
        (delegate) => delegate.crossAxisCount,
        'crossAxisCount',
        2,
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('task-target-plot-11')));
    await tester.pump();
    expect(find.text('Seterusnya'), findsOneWidget);
    await tester.tap(find.byKey(const Key('task-target-continue-button')));
    await tester.pumpAndSettle();
    expect(selectedPlot?.id, 11);
  });

  testWidgets('project cell opens a two-column plot detail grid', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const project = ProjectRecord(
      key: 'pineapple::projek-detail',
      projectName: 'Projek Detail',
      location: 'Pontian, Johor',
      cropTypes: [
        ProjectCropType(code: 'pineapple', name: 'Nanas'),
        ProjectCropType(code: 'coconut', name: 'Kelapa'),
      ],
      plots: [
        PlotRecord(
          id: 1,
          name: 'Plot A',
          cropCode: 'pineapple',
          cropName: 'Nanas',
          imagePath: 'assets/images/seeds/pineapple_fruit.png',
          varieties: [
            CropVariety(code: 'AC1', name: 'Moris'),
            CropVariety(code: 'AC5', name: 'Josapine'),
          ],
          raisedBedCount: 12,
          plantedAt: null,
        ),
        PlotRecord(
          id: 2,
          name: 'Plot B',
          cropCode: 'coconut',
          cropName: 'Kelapa',
          imagePath: 'assets/images/seeds/coconut_fruit.png',
          varieties: [CropVariety(code: 'CN13', name: 'Matag Green')],
          raisedBedCount: 8,
          plantedAt: null,
        ),
      ],
    );
    final repository = _MemoryProjectRepository(projects: const [project]);
    final raisedBedRepository = _MemoryRaisedBedRepository(
      List.generate(
        12,
        (index) => RaisedBedRecord(
          id: index + 1,
          plotId: 1,
          bedNumber: index + 1,
          seedlingCount: null,
        ),
      ),
    );
    final taskRepository = _MemoryTaskRepository(
      List.generate(
        12,
        (index) => RaisedBedRecord(
          id: index + 1,
          plotId: 1,
          bedNumber: index + 1,
          seedlingCount: null,
        ),
      ),
    );
    final controller = ProjectController(repository);
    addTearDown(controller.dispose);
    await controller.loadProjects();
    var plotDataRefreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: Scaffold(
          body: ProjectView(
            controller: controller,
            raisedBedRepository: raisedBedRepository,
            taskRepository: taskRepository,
            onPlotDataChanged: () async => plotDataRefreshCount++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nanas'), findsOneWidget);
    expect(find.text('Kelapa'), findsOneWidget);
    expect(find.text('12 batas'), findsOneWidget);
    expect(find.text('8 baris'), findsOneWidget);
    final cropPills = find.byKey(
      const ValueKey<String>(
        'project-card-crop-pills-pineapple::projek-detail',
      ),
    );
    expect(
      find.descendant(of: cropPills, matching: find.byType(Image)),
      findsNothing,
    );
    expect(find.text('Pontian, Johor'), findsOneWidget);
    final projectLocationIcon = tester.widget<Image>(
      find.byKey(
        const ValueKey<String>(
          'project-card-location-icon-pineapple::projek-detail',
        ),
      ),
    );
    expect(
      (projectLocationIcon.image as AssetImage).assetName,
      'assets/images/icon_location.png',
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(
              const ValueKey<String>(
                'project-card-location-icon-pineapple::projek-detail',
              ),
            ),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey<String>(
                  'project-card-crop-pills-pineapple::projek-detail',
                ),
              ),
            )
            .dy,
      ),
    );
    final plotScroll = find.byKey(
      const ValueKey<String>('project-plot-scroll-pineapple::projek-detail'),
    );
    expect(plotScroll, findsOneWidget);
    expect(
      tester.getSize(plotScroll).width,
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>(
                'project-card-content-pineapple::projek-detail',
              ),
            ),
          )
          .width,
    );
    expect(
      find.byKey(const ValueKey<String>('project-plot-preview-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('project-plot-preview-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'project-plot-left-fade-pineapple::projek-detail',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'project-plot-right-fade-pineapple::projek-detail',
        ),
      ),
      findsOneWidget,
    );
    await tester.drag(plotScroll, const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>(
          'project-plot-left-fade-pineapple::projek-detail',
        ),
      ),
      findsOneWidget,
    );
    final deleteButton = find.byKey(
      const ValueKey<String>('delete-project-pineapple::projek-detail'),
    );
    expect(deleteButton, findsOneWidget);
    final projectSummary = find.byKey(
      const ValueKey<String>('project-card-summary-pineapple::projek-detail'),
    );
    expect(
      (tester.getCenter(deleteButton).dy -
              tester.getRect(projectSummary).center.dy)
          .abs(),
      lessThan(1),
    );
    final projectCellInkWell = tester.widget<InkWell>(
      find
          .ancestor(
            of: find.text('Projek Detail'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(projectCellInkWell.splashFactory, NoSplash.splashFactory);
    final deleteImage = tester.widget<Image>(
      find.descendant(of: deleteButton, matching: find.byType(Image)),
    );
    expect(
      (deleteImage.image as AssetImage).assetName,
      'assets/images/icon_delete.png',
    );

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-confirmation-sheet')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('app-confirmation-sheet'))).height,
      lessThan(844 * 0.76),
    );
    expect(find.text('Padam projek?'), findsOneWidget);
    expect(find.text('Ya, Padam'), findsOneWidget);
    final confirmationImage = tester.widget<Image>(
      find.byKey(const Key('app-confirmation-sheet-image')),
    );
    expect(
      (confirmationImage.image as AssetImage).assetName,
      'assets/images/trash.png',
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Projek Detail'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectDetailView), findsOneWidget);
    final projectDetailAppBar = tester.widget<SliverAppBar>(
      find.byType(SliverAppBar),
    );
    expect(
      projectDetailAppBar.titleTextStyle?.fontSize,
      AppTypography.navigationTitleFontSize,
    );
    expect(
      projectDetailAppBar.titleTextStyle?.fontWeight,
      AppTypography.navigationTitleFontWeight,
    );
    expect(projectDetailAppBar.centerTitle, isTrue);
    expect(find.byKey(const Key('edit-project-button')), findsOneWidget);
    final projectDetailLocationIcon = tester.widget<Image>(
      find.byKey(const Key('project-detail-location-icon')),
    );
    expect(
      (projectDetailLocationIcon.image as AssetImage).assetName,
      'assets/images/icon_location.png',
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('project-detail-location-icon')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('project-detail-crop-pills')))
            .dy,
      ),
    );

    await tester.tap(find.byKey(const Key('edit-project-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-edit-sheet')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('project-edit-sheet'))).height,
      lessThan(844 * 0.72),
    );
    expect(find.text('Langkah 1 daripada 2'), findsOneWidget);
    expect(find.text('Namakan projek anda'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('project-edit-name-field')),
      'Projek Detail Baharu',
    );
    await tester.tap(find.byKey(const Key('continue-project-edit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 2 daripada 2'), findsOneWidget);
    expect(find.text('Di manakah projek ini?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('project-edit-location-field')),
      'Muar, Johor',
    );
    await tester.tap(find.byKey(const Key('save-project-edit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Projek Detail Baharu'), findsOneWidget);
    expect(find.text('Muar, Johor'), findsOneWidget);
    expect(find.text('Plot A'), findsOneWidget);
    expect(find.text('Plot B'), findsOneWidget);
    final plotGrid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final gridDelegate =
        plotGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(gridDelegate.crossAxisCount, 2);
    expect(gridDelegate.mainAxisExtent, 255);
    final firstPlotVarieties = tester.widget<Text>(
      find.byKey(const ValueKey<String>('project-detail-plot-varieties-1')),
    );
    expect(firstPlotVarieties.maxLines, 1);
    expect(firstPlotVarieties.overflow, TextOverflow.ellipsis);
    final addPlotButton = find.byKey(const Key('add-plot-button'));
    expect(addPlotButton, findsOneWidget);
    expect(
      tester.widget<FloatingActionButton>(addPlotButton).shape,
      isA<CircleBorder>(),
    );

    await tester.tap(addPlotButton);
    await tester.pumpAndSettle();
    expect(find.text('Senarai Tanaman'), findsOneWidget);
    await tester.tap(find.byKey(const Key('teruskan-button')));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 1 daripada 2'), findsOneWidget);
    expect(find.text('Namakan plot tanaman'), findsOneWidget);
    await tester.tap(find.byKey(const Key('project-form-leading-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plot A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PlotDetailView), findsOneWidget);
    final editPlotButton = find.byKey(const Key('edit-plot-button'));
    expect(editPlotButton, findsOneWidget);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).titleTextStyle?.fontSize,
      AppTypography.navigationTitleFontSize,
    );
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
      AppColors.green,
    );
    expect(tester.widget<AppBar>(find.byType(AppBar)).bottom, isNotNull);
    expect(find.byKey(const Key('plot-crop-summary-card')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('plot-variety-dot-0'))),
      const Size.square(5),
    );
    expect(find.text('Tugasan'), findsOneWidget);
    expect(find.text('Batas'), findsOneWidget);
    expect(find.text('Tiada Tugasan'), findsOneWidget);
    expect(find.byKey(const Key('empty-task-tractor')), findsOneWidget);
    final addTaskButton = find.byKey(const Key('add-task-button'));
    expect(addTaskButton, findsOneWidget);
    expect(tester.getSize(addTaskButton).width, lessThan(350));
    expect(find.byKey(const Key('raised-bed-grid')), findsNothing);

    await tester.tap(editPlotButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Langkah 1 daripada 2'), findsOneWidget);
    expect(find.text('Plot A'), findsWidgets);
    final deletePlotButton = find.byKey(const Key('delete-plot-button'));
    final continuePlotButton = find.byKey(
      const Key('project-form-continue-button'),
    );
    expect(deletePlotButton, findsOneWidget);
    expect(
      tester.getCenter(deletePlotButton).dx,
      lessThan(tester.getCenter(continuePlotButton).dx),
    );
    await tester.tap(deletePlotButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Padam plot?'), findsOneWidget);
    expect(find.text('Ya, Padam'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('project-form-leading-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(addTaskButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('task-form-sheet')), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('task-form-sheet')), findsNothing);
    await tester.tap(addTaskButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('task-form-sheet')), findsOneWidget);
    expect(find.text('Masa Tugasan'), findsNothing);
    expect(find.byKey(const Key('task-time-button')), findsNothing);
    final taskTypeGrid = tester.widget<GridView>(
      find.byKey(const Key('task-type-grid')),
    );
    final taskTypeGridDelegate =
        taskTypeGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(taskTypeGridDelegate.crossAxisCount, 3);
    expect(find.text('Kawalan Rumpai'), findsOneWidget);
    final fertilizingImage = tester.widget<Image>(
      find.byKey(const ValueKey<String>('task-type-image-fertilizing')),
    );
    expect(
      fertilizingImage.image,
      const AssetImage('assets/images/tasks/fertilizing.png'),
    );
    final unselectedFertilizingPill = tester.widget<Container>(
      find.byKey(const ValueKey<String>('task-type-label-pill-fertilizing')),
    );
    expect(
      (unselectedFertilizingPill.decoration as BoxDecoration).color,
      const Color(0xFFF7F8F7),
    );
    expect(
      unselectedFertilizingPill.constraints?.hasBoundedHeight ?? false,
      isFalse,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('task-type-fertilizing')),
    );
    await tester.pump();
    expect(find.byKey(const Key('task-control-method-selector')), findsNothing);
    final selectedFertilizingPill = tester.widget<Container>(
      find.byKey(const ValueKey<String>('task-type-label-pill-fertilizing')),
    );
    expect(
      (selectedFertilizingPill.decoration as BoxDecoration).color,
      AppColors.primaryAction,
    );
    await tester.tap(find.byKey(const Key('task-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('Masa Tugasan'), findsOneWidget);
    expect(find.byKey(const Key('task-time-button')), findsOneWidget);
    expect(find.text('7:30 pagi'), findsOneWidget);
    final specificRaisedBedsOption = find.byKey(
      const Key('specific-raised-beds-option'),
    );
    await tester.ensureVisible(specificRaisedBedsOption);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(specificRaisedBedsOption);
    await tester.pump();
    await tester.tap(find.byKey(const Key('open-raised-bed-picker-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('raised-bed-picker-sheet')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('raised-bed-range-field')),
      '1-3, 5',
    );
    await tester.tap(find.byKey(const Key('apply-raised-bed-range-button')));
    await tester.pump();
    expect(find.text('Gunakan (4)'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('confirm-raised-bed-selection-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.byKey(const Key('task-notes-field')),
      'Baja mengikut jadual plot.',
    );
    await tester.ensureVisible(find.byKey(const Key('save-task-button')));
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('task-grid')), findsOneWidget);
    final now = DateTime.now();
    const shortMonths = <String>[
      'Jan',
      'Feb',
      'Mac',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ogo',
      'Sep',
      'Okt',
      'Nov',
      'Dis',
    ];
    final monthSelector = find.byKey(const Key('task-month-selector'));
    expect(monthSelector, findsOneWidget);
    expect(
      find.text('${shortMonths[now.month - 1]}, ${now.year}'),
      findsOneWidget,
    );
    expect(tester.getSize(monthSelector).width, lessThan(200));
    expect(find.byKey(const Key('task-timeline-line')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('task-timeline-line'))).height,
      lessThan(844),
    );
    final timelineLine = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('task-timeline-line')),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((timelineLine.decoration as BoxDecoration).gradient, isNotNull);
    expect(find.byKey(const Key('current-date-dot')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('task-date-column'))).width, 41);
    expect(find.text('Membaja'), findsOneWidget);
    expect(find.text('7:30 pagi'), findsOneWidget);
    final taskListImage = tester.widget<Image>(
      find.byKey(const ValueKey<String>('task-list-image-fertilizing')),
    );
    expect(
      taskListImage.image,
      const AssetImage('assets/images/tasks/fertilizing.png'),
    );
    expect(find.text('4 batas dipilih'), findsOneWidget);
    expect(find.text('Baja mengikut jadual plot.'), findsNothing);
    expect(find.byKey(const Key('add-task-floating-button')), findsOneWidget);

    await tester.tap(monthSelector);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('month-year-picker-sheet')), findsOneWidget);
    expect(find.byKey(const Key('month-picker-grid')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsNothing);
    final emptyMonth = now.month == 1 ? 2 : 1;
    final emptyMonthOption = find.byKey(
      ValueKey<String>('month-option-$emptyMonth'),
    );
    final emptyMonthContainer = tester.widget<AnimatedContainer>(
      find.descendant(
        of: emptyMonthOption,
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (emptyMonthContainer.decoration as BoxDecoration).color,
      const Color(0xFFF7F8F7),
    );
    await tester.tap(emptyMonthOption);
    await tester.tap(find.byKey(const Key('confirm-month-picker-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('0 tugasan'), findsOneWidget);
    expect(find.byKey(const Key('empty-month-task-tractor')), findsOneWidget);
    expect(find.text('Tiada Tugasan'), findsOneWidget);
    expect(find.text('Tiada tugasan untuk bulan ini.'), findsOneWidget);
    expect(find.text('TARIKH'), findsNothing);
    expect(find.text('TUGASAN'), findsNothing);
    expect(find.byKey(const Key('task-timeline-line')), findsNothing);
    expect(find.byKey(const Key('current-date-dot')), findsNothing);

    await tester.tap(monthSelector);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(ValueKey<String>('month-option-${now.month}')));
    await tester.tap(find.byKey(const Key('confirm-month-picker-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('task-timeline-line')), findsOneWidget);

    await tester.tap(find.text('Membaja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TaskDetailView), findsOneWidget);
    expect(find.byKey(const Key('edit-task-button')), findsOneWidget);
    expect(find.text('Ubah'), findsOneWidget);
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).titleTextStyle?.fontSize,
      AppTypography.navigationTitleFontSize,
    );
    expect(find.byKey(const Key('complete-task-button')), findsOneWidget);
    final taskDetailImage = tester.widget<Image>(
      find.byKey(const Key('task-detail-type-image')),
    );
    expect(
      taskDetailImage.image,
      const AssetImage('assets/images/tasks/fertilizing.png'),
    );
    expect(
      tester.getSize(find.byKey(const Key('task-detail-type-image'))),
      const Size.square(150),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('task-detail-type-label'))).dy,
      greaterThan(
        tester
            .getBottomLeft(find.byKey(const Key('task-detail-type-image')))
            .dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('task-detail-status-pill'))).dy,
      greaterThan(
        tester
            .getBottomLeft(find.byKey(const Key('task-detail-type-label')))
            .dy,
      ),
    );
    expect(find.text('01, 02, 03, 05'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('task-raised-bed-dot-1')),
        matching: find.text('01'),
      ),
      findsOneWidget,
    );
    expect(find.text('Baja mengikut jadual plot.'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
    expect(find.text('Masa Tugasan'), findsOneWidget);
    expect(find.text('7:30 pagi'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('task-raised-bed-dots')),
        matching: find.byType(Container),
      ),
      findsNWidgets(4),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('task-raised-bed-dot-1')),
      ),
      const Size.square(28),
    );
    expect(find.text('Jenis Kawalan'), findsOneWidget);
    expect(find.text('Kimia'), findsOneWidget);
    final chemicalMethod = find.byKey(
      const ValueKey<String>('task-detail-control-method-chemical'),
    );
    await tester.ensureVisible(chemicalMethod);
    await tester.tap(chemicalMethod);
    await tester.pumpAndSettle();
    expect(find.text('Senarai Baja'), findsOneWidget);
    expect(
      find.byKey(const Key('control-product-search-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fertilizer-category-tabs')), findsOneWidget);
    expect(find.text('Baja Cecair'), findsWidgets);
    expect(find.text('Baja Butiran'), findsOneWidget);
    expect(find.text('Baja Cecair NPK Seimbang'), findsOneWidget);
    expect(
      find.text(
        'Pilih formulasi dan kadar berdasarkan keperluan tanaman, ujian tanah serta label pengilang.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('control-product-Baja Cecair NPK Seimbang'),
      ),
    );
    await tester.pump();
    final selectedPrimaryDetailPill = tester.widget<Container>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>(
            'control-product-primary-detail-Baja Cecair NPK Seimbang',
          ),
        ),
        matching: find.byType(Container),
      ),
    );
    final selectedPrimaryDetailDecoration =
        selectedPrimaryDetailPill.decoration as BoxDecoration;
    expect(selectedPrimaryDetailDecoration.border, isNotNull);
    expect((selectedPrimaryDetailDecoration.border! as Border).top.width, 1);
    expect(
      (selectedPrimaryDetailDecoration.border! as Border).top.color,
      AppColors.primaryAction,
    );
    final selectedSecondaryDetailPill = tester.widget<Container>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>(
            'control-product-secondary-detail-Baja Cecair NPK Seimbang',
          ),
        ),
        matching: find.byType(Container),
      ),
    );
    final selectedSecondaryDetailDecoration =
        selectedSecondaryDetailPill.decoration as BoxDecoration;
    expect((selectedSecondaryDetailDecoration.border! as Border).top.width, 1);
    expect(
      (selectedSecondaryDetailDecoration.border! as Border).top.color,
      const Color(0xFFB8C0BC),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('product-category-granular')),
    );
    await tester.pump();
    expect(find.text('Baja Sebatian NPK Seimbang'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('control-product-search-field')),
      'Urea',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('control-product-Urea')),
      findsOneWidget,
    );
    expect(find.text('Baja Sebatian NPK Seimbang'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('control-product-Urea')),
    );
    await tester.pump();
    expect(find.text('Gunakan (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-control-products-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('selected-control-product-pills')),
      findsOneWidget,
    );
    expect(find.text('NPK 20-20-20'), findsOneWidget);
    expect(find.text('46% Nitrogen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-task-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ubah Tugasan'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('task-type-weed_control')),
    );
    await tester.tap(find.byKey(const Key('task-next-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-task-button')));
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kawalan Rumpai'), findsOneWidget);

    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('complete-task-button')))
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('task-detail-control-method-organic')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('complete-task-button')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Tugasan Selesai'), findsOneWidget);
    expect(find.text('Ubah tugasan ini kepada telah selesai?'), findsOneWidget);
    expect(
      tester
          .widget<Image>(find.byKey(const Key('app-confirmation-sheet-image')))
          .image,
      const AssetImage('assets/images/pump_sprayer.png'),
    );
    await tester.tap(
      find.byKey(const Key('app-confirmation-sheet-confirm-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('complete-task-button')))
          .backgroundColor,
      const Color.fromARGB(255, 137, 192, 157),
    );

    await tester.tap(find.byKey(const Key('complete-task-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Tugasan Diselesaikan'), findsOneWidget);
    expect(find.text('Ubah tugasan ini kepada belum selesai?'), findsOneWidget);
    expect(
      tester
          .widget<Image>(find.byKey(const Key('app-confirmation-sheet-image')))
          .image,
      const AssetImage('assets/images/farmer_with_pump_sprayer.png'),
    );
    Navigator.of(
      tester.element(find.byKey(const Key('app-confirmation-sheet'))),
    ).pop(false);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kawalan Rumpai'), findsOneWidget);
    final completedTaskIcon = find.byKey(const Key('completed-task-icon'));
    expect(completedTaskIcon, findsOneWidget);
    expect(tester.getSize(completedTaskIcon), const Size.square(30));
    final completedTaskImage = tester.widget<Image>(
      find.descendant(of: completedTaskIcon, matching: find.byType(Image)),
    );
    expect(
      completedTaskImage.image,
      const AssetImage('assets/images/completed.png'),
    );
    expect(completedTaskImage.color, Colors.white);
    expect(completedTaskImage.colorBlendMode, BlendMode.srcIn);
    final completedTaskCard = tester.widget<Material>(
      find.byKey(const ValueKey<int>(1)),
    );
    expect(completedTaskCard.color, const Color(0xFF088A4F));
    expect(
      tester.getCenter(completedTaskIcon).dx,
      greaterThan(tester.getCenter(find.byKey(const ValueKey<int>(1))).dx),
    );
    expect(
      (completedTaskCard.shape as RoundedRectangleBorder).side,
      BorderSide.none,
    );

    await tester.tap(find.text('Kawalan Rumpai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('edit-task-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final removeTaskButton = find.byKey(const Key('delete-task-button'));
    expect(removeTaskButton, findsOneWidget);
    expect(find.byKey(const Key('task-next-button')), findsOneWidget);
    expect(
      tester.widget<IconButton>(removeTaskButton).color,
      const Color(0xFFE53935),
    );

    await tester.tap(removeTaskButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('app-confirmation-sheet')), findsOneWidget);
    expect(find.text('Buang tugasan?'), findsOneWidget);
    expect(
      find.text('Tugasan ini akan dipadam dan tidak boleh dipulihkan.'),
      findsOneWidget,
    );
    expect(find.text('Ya, Buang'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('app-confirmation-sheet-confirm-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(TaskDetailView), findsNothing);
    expect(taskRepository.tasks, isEmpty);
    expect(find.byKey(const Key('empty-task-tractor')), findsOneWidget);

    await tester.tap(find.text('Batas'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('raised-bed-grid')), findsOneWidget);
    final raisedBedGrid = tester.widget<SliverGrid>(
      find.byKey(const Key('raised-bed-grid')),
    );
    final raisedBedGridDelegate =
        raisedBedGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(raisedBedGridDelegate.crossAxisCount, 5);
    expect(find.text('0/12'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('raised-bed-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('seedling-count-sheet')), findsOneWidget);
    expect(find.byKey(const Key('raised-bed-variety-options')), findsOneWidget);
    expect(find.text('AC1 - Moris'), findsOneWidget);
    expect(find.text('AC5 - Josapine'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('seedling-preset-500')));
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('save-seedling-count-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('save-and-next-button')))
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('raised-bed-variety-AC1')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('raised-bed-variety-AC5')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('save-seedling-count-button')),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('save-and-next-button')))
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-seedling-count-button')),
    );
    await tester.tap(find.byKey(const Key('save-seedling-count-button')));
    await tester.pumpAndSettle();

    expect(find.text('1/12'), findsOneWidget);
    expect(plotDataRefreshCount, 1);
    expect(find.text('500'), findsWidgets);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('raised-bed-variety-label-1')),
          )
          .data,
      'AC1 +1',
    );

    await tester.tap(find.byKey(const ValueKey<String>('raised-bed-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('seedling-count-field')), '0');
    await tester.ensureVisible(
      find.byKey(const Key('save-seedling-count-button')),
    );
    await tester.tap(find.byKey(const Key('save-seedling-count-button')));
    await tester.pumpAndSettle();

    expect(find.text('0/12'), findsOneWidget);
    expect(plotDataRefreshCount, 2);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('raised-bed-1'), skipOffstage: false),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('raised-bed-1')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('bulk-seedling-count-button')),
    );
    await tester.tap(find.byKey(const Key('bulk-seedling-count-button')));
    await tester.pumpAndSettle();
    expect(find.text('Tetapkan Varieti Secara Pukal'), findsOneWidget);
    expect(find.byKey(const Key('raised-bed-variety-options')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('seedling-preset-300')));
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('save-seedling-count-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('raised-bed-variety-AC5')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('save-seedling-count-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-seedling-count-button')),
    );
    await tester.tap(find.byKey(const Key('save-seedling-count-button')));
    await tester.pumpAndSettle();
    expect(find.text('12/12'), findsOneWidget);
    expect(plotDataRefreshCount, 3);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('raised-bed-variety-label-1')),
          )
          .data,
      'AC5',
    );
  });

  testWidgets('task detail shows one numbered 28px dot per involved bed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final raisedBeds = List.generate(
      60,
      (index) => RaisedBedRecord(
        id: index + 1,
        plotId: 1,
        bedNumber: index + 1,
        seedlingCount: null,
      ),
    );
    final repository = _MemoryTaskRepository(raisedBeds);
    final task = PlotTaskRecord(
      id: 1,
      plotId: 1,
      type: FarmTaskType.fertilizing,
      scheduledAt: DateTime(2026, 9, 23),
      notes: '',
      raisedBedNumbers: [],
      isCompleted: false,
      completedAt: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: TaskDetailView(
          task: task,
          projectName: 'Projek Utama',
          plotName: 'Plot A',
          totalRaisedBeds: 60,
          raisedBeds: raisedBeds,
          repository: repository,
          onTaskChanged: (_) {},
          onTaskDeleted: (_) {},
        ),
      ),
    );

    expect(find.text('Projek Utama'), findsOneWidget);
    expect(find.text('Plot A'), findsOneWidget);
    final projectPillDecoration =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byKey(const Key('task-detail-project-pill')),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(projectPillDecoration.borderRadius, BorderRadius.circular(10));
    expect(projectPillDecoration.color, AppColors.creamDark);
    expect(
      (projectPillDecoration.border as Border).top.color,
      AppColors.creamDeep,
    );
    final breadcrumb = find.byKey(const Key('task-detail-location-breadcrumb'));
    expect(
      tester.widget<SingleChildScrollView>(breadcrumb).scrollDirection,
      Axis.horizontal,
    );
    expect(
      find.descendant(of: breadcrumb, matching: find.byType(Expanded)),
      findsNothing,
    );
    final breadcrumbArrow = tester.widget<Image>(
      find.byKey(const Key('task-detail-breadcrumb-arrow')),
    );
    expect(
      breadcrumbArrow.image,
      const AssetImage('assets/images/icon_arrow_right.png'),
    );
    expect(breadcrumbArrow.color, AppColors.creamDeep);

    final dots = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'task-raised-bed-dot-',
          ),
    );
    expect(dots, findsNWidgets(60));
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('task-raised-bed-dot-60')),
      ),
      const Size.square(28),
    );
    final firstRaisedBedNumber = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('task-raised-bed-dot-1')),
        matching: find.text('01'),
      ),
    );
    expect(firstRaisedBedNumber.style?.fontSize, 10);
    expect(firstRaisedBedNumber.style?.fontWeight, FontWeight.w500);
    expect(firstRaisedBedNumber.style?.color, const Color(0xFF705C21));
    expect(find.byType(Divider), findsNothing);

    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('complete-task-button')))
          .onPressed,
      isNull,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: TaskDetailView(
          key: const Key('task-with-control-method'),
          task: task.copyWith(controlMethod: TaskControlMethod.organic),
          projectName: 'Projek Utama',
          plotName: 'Plot A',
          totalRaisedBeds: 60,
          raisedBeds: raisedBeds,
          repository: repository,
          onTaskChanged: (_) {},
          onTaskDeleted: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('complete-task-button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('AppButton supports custom height, font size, and font weight', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: AppButton(
                key: const Key('custom-app-button'),
                label: 'Custom',
                height: 44,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final appButton = find.byKey(const Key('custom-app-button'));
    expect(tester.getSize(appButton).height, 44);

    final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      filledButton.style?.textStyle?.resolve(<WidgetState>{})?.fontWeight,
      FontWeight.w500,
    );
    expect(
      filledButton.style?.textStyle?.resolve(<WidgetState>{})?.fontSize,
      15,
    );
  });

  testWidgets('reminder settings supports day, hour, and minute units', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: ReminderSettingsView(
          repository: _MemoryNotificationSettingsRepository(),
          taskRepository: _MemoryTaskRepository(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hari'), findsOneWidget);
    expect(find.text('Jam'), findsOneWidget);
    expect(find.text('Minit'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Tetapan Bunyi Notifikasi')).dy,
      lessThan(tester.getTopLeft(find.text('Ingatkan Saya')).dy),
    );

    for (final key in const [
      Key('reminder-toggle-card'),
      Key('reminder-counter-card'),
    ]) {
      final decoration = tester.widget<Container>(find.byKey(key)).decoration;
      final border = (decoration as BoxDecoration).border! as Border;
      expect(border.top.color, AppColors.cellBorder);
      expect(border.top.width, 1);
    }

    await tester.tap(find.text('Jam'));
    await tester.pump();
    final amountField = tester.widget<TextField>(
      find.byKey(const Key('reminder-amount-field')),
    );
    expect(amountField.controller?.text, '12');

    expect(find.text('Pratonton Notifikasi'), findsOneWidget);
    expect(find.text('Waktu Mula Tugasan'), findsNothing);
    expect(find.text('Kawalan Serangga'), findsOneWidget);
    expect(
      find.byKey(const Key('notification-preview-task-image')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Ini adalah peringatan mesra berkenaan tugasan yang telah anda '
        'rekodkan. Tugasan ini dijadualkan akan bermula pada pukul '
        '7:30 pagi, 24 Oktober 2026.',
      ),
      findsOneWidget,
    );
    expect(find.text('Uji Notifikasi'), findsOneWidget);
    expect(
      find.byKey(const Key('test-rich-notification-button')),
      findsOneWidget,
    );
    final testNotificationButton = tester.widget<TextButton>(
      find.byKey(const Key('test-rich-notification-button')),
    );
    expect(
      testNotificationButton.style?.foregroundColor?.resolve({}),
      AppColors.primaryAction,
    );
    expect(
      testNotificationButton.style?.backgroundColor?.resolve({}),
      Colors.transparent,
    );
    expect(testNotificationButton.style?.side?.resolve({}), isNull);
    expect(
      tester.widget<Text>(find.text('Uji Notifikasi')).style?.decoration,
      isNull,
    );
    expect(
      find.byKey(const Key('save-reminder-settings-button')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('notification-sound-settings-card')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tetapan Bunyi Notifikasi'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('notification-sound-settings-card')),
        matching: find.text('Peringatan'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('choose-notification-sound-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('notification-sound-picker-sheet')),
      findsOneWidget,
    );
    expect(find.text('Peranti'), findsWidgets);
    expect(find.text('Haiwan'), findsWidgets);

    final cowSound = find.byKey(const Key('notification-sound-lembu'));
    await tester.scrollUntilVisible(
      cowSound,
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('notification-sound-picker-sheet')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(cowSound);
    await tester.pumpAndSettle();
    expect(find.text('Lembu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification-sound-toggle')));
    await tester.pump();
    expect(find.text('Notifikasi akan dihantar tanpa bunyi.'), findsOneWidget);
  });

  testWidgets('task calendar keeps its size when search keyboard opens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        theme: AppTheme.light,
        home: TaskScheduleView(repository: _MemoryHomeRepository(const [])),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.resizeToAvoidBottomInset, isFalse);

    await tester.tap(find.byKey(const Key('task-schedule-search-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('task-schedule-search-field')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    final calendarGrid = find.byKey(const Key('task-schedule-calendar-grid'));
    final sizeBeforeKeyboard = tester.getSize(calendarGrid);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();

    expect(tester.getSize(calendarGrid), sizeBeforeKeyboard);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryNotificationSettingsRepository
    implements NotificationSettingsRepository {
  NotificationReminderSettings settings = NotificationReminderSettings.defaults;

  @override
  Future<NotificationReminderSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(NotificationReminderSettings value) async {
    settings = value;
  }
}

class _MemoryCropSelectionRepository implements CropSelectionRepository {
  String? _selectedCropCode;

  @override
  Future<void> clearSelectedCrop() async {
    _selectedCropCode = null;
  }

  @override
  Future<String?> getSelectedCropCode() async => _selectedCropCode;

  @override
  Future<void> saveSelectedCrop(CropOption crop) async {
    _selectedCropCode = crop.code;
  }
}

class _MemoryProjectRepository implements ProjectRepository {
  _MemoryProjectRepository({List<ProjectRecord> projects = const []})
    : projects = List.of(projects);

  List<ProjectRecord> projects;

  @override
  Future<int> createProject(ProjectFormData data) async => 1;

  @override
  Future<void> updatePlot({
    required int plotId,
    required ProjectFormData data,
  }) async {}

  @override
  Future<void> updateProject({
    required String currentProjectName,
    required String projectName,
    required String location,
  }) async {
    projects = projects
        .map(
          (project) => project.projectName == currentProjectName
              ? ProjectRecord(
                  key: projectName.trim().toLowerCase(),
                  projectName: projectName.trim(),
                  location: location.trim(),
                  cropTypes: project.cropTypes,
                  plots: project.plots,
                )
              : project,
        )
        .toList(growable: false);
  }

  @override
  Future<void> deletePlot(int plotId) async {
    final updatedProjects = <ProjectRecord>[];
    for (final project in projects) {
      final remainingPlots = project.plots
          .where((plot) => plot.id != plotId)
          .toList(growable: false);
      if (remainingPlots.length == project.plots.length) {
        updatedProjects.add(project);
        continue;
      }
      if (remainingPlots.isEmpty) continue;
      final cropCodes = remainingPlots.map((plot) => plot.cropCode).toSet();
      updatedProjects.add(
        ProjectRecord(
          key: project.key,
          projectName: project.projectName,
          location: project.location,
          cropTypes: project.cropTypes
              .where((crop) => cropCodes.contains(crop.code))
              .toList(growable: false),
          plots: remainingPlots,
        ),
      );
    }
    projects = updatedProjects;
  }

  @override
  Future<void> deleteProject(String projectName) async {}

  @override
  Future<ProjectFormSuggestions> getFormSuggestions() async {
    return const ProjectFormSuggestions();
  }

  @override
  Future<List<ProjectRecord>> getProjects() async => projects;
}

class _MemoryHomeRepository implements HomeRepository {
  _MemoryHomeRepository(this.tasks, {List<PlotOverview>? plotOverviews})
    : plotOverviews = plotOverviews ?? _defaultPlotOverviews;

  final List<UpcomingTaskRecord> tasks;
  final List<PlotOverview> plotOverviews;
  int scheduleLoadCount = 0;

  static const _defaultPlotOverviews = [
    PlotOverview(
      plotId: 101,
      projectName: 'Projek Selatan',
      plotName: 'Plot Nanas',
      cropCode: 'pineapple',
      cropName: 'Nanas',
      imagePath: 'assets/images/seeds/pineapple_fruit.png',
      totalPlants: 1800,
      daysToHarvest: 42,
      estimatedHarvestAt: null,
    ),
    PlotOverview(
      plotId: 102,
      projectName: 'Projek Timur',
      plotName: 'Plot Kelapa',
      cropCode: 'coconut',
      cropName: 'Kelapa',
      imagePath: 'assets/images/seeds/coconut_fruit.png',
      totalPlants: 96,
      daysToHarvest: 75,
      estimatedHarvestAt: null,
    ),
    PlotOverview(
      plotId: 103,
      projectName: 'Projek Tengah',
      plotName: 'Plot Nanas Dua',
      cropCode: 'pineapple',
      cropName: 'Nanas',
      imagePath: 'assets/images/seeds/pineapple_fruit.png',
      totalPlants: 720,
      daysToHarvest: 64,
      estimatedHarvestAt: null,
    ),
    PlotOverview(
      plotId: 104,
      projectName: 'Projek Utara',
      plotName: 'Plot Kelapa Dua',
      cropCode: 'coconut',
      cropName: 'Kelapa',
      imagePath: 'assets/images/seeds/coconut_fruit.png',
      totalPlants: 48,
      daysToHarvest: 88,
      estimatedHarvestAt: null,
    ),
    PlotOverview(
      plotId: 105,
      projectName: 'Projek Barat',
      plotName: 'Plot Nanas Tiga',
      cropCode: 'pineapple',
      cropName: 'Nanas',
      imagePath: 'assets/images/seeds/pineapple_fruit.png',
      totalPlants: 420,
      daysToHarvest: 91,
      estimatedHarvestAt: null,
    ),
  ];

  @override
  Future<List<PlotOverview>> getPlotOverviews({DateTime? now}) async {
    return List.unmodifiable(plotOverviews);
  }

  @override
  Future<List<UpcomingTaskRecord>> getUpcomingTasks({
    DateTime? fromDate,
  }) async {
    return List.unmodifiable(tasks);
  }

  @override
  Future<List<TaskScheduleRecord>> getScheduledTasksForMonth(
    DateTime month,
  ) async {
    scheduleLoadCount++;
    return tasks
        .where(
          (task) =>
              task.scheduledAt.year == month.year &&
              task.scheduledAt.month == month.month,
        )
        .map(
          (task) => TaskScheduleRecord(
            id: task.id,
            plotId: task.plotId,
            type: task.type,
            cropCode: task.cropCode,
            cropName: task.cropName,
            projectName: task.projectName,
            plotName: task.plotName,
            location: task.location,
            scheduledAt: task.scheduledAt,
            isCompleted: false,
          ),
        )
        .toList(growable: false);
  }
}

class _MemoryRaisedBedRepository implements RaisedBedRepository {
  _MemoryRaisedBedRepository(List<RaisedBedRecord> raisedBeds)
    : _raisedBeds = List.of(raisedBeds);

  List<RaisedBedRecord> _raisedBeds;

  @override
  Future<List<RaisedBedRecord>> getRaisedBeds(int plotId) async {
    return _raisedBeds
        .where((raisedBed) => raisedBed.plotId == plotId)
        .toList(growable: false);
  }

  @override
  Future<void> saveBulkRaisedBedDetails({
    required int plotId,
    required int seedlingCount,
    required bool onlyUnset,
    required List<CropVariety> varieties,
  }) async {
    final storedCount = seedlingCount == 0 ? null : seedlingCount;
    _raisedBeds = _raisedBeds
        .map(
          (raisedBed) =>
              raisedBed.plotId == plotId &&
                  (!onlyUnset || !raisedBed.isConfigured)
              ? raisedBed.withDetails(
                  seedlingCount: storedCount,
                  varieties: varieties,
                )
              : raisedBed,
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveSeedlingCount({
    required int plotId,
    required int bedNumber,
    required int seedlingCount,
  }) async {
    final storedCount = seedlingCount == 0 ? null : seedlingCount;
    _raisedBeds = _raisedBeds
        .map(
          (raisedBed) =>
              raisedBed.plotId == plotId && raisedBed.bedNumber == bedNumber
              ? raisedBed.withSeedlingCount(storedCount)
              : raisedBed,
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveRaisedBedDetails({
    required int plotId,
    required int bedNumber,
    required int seedlingCount,
    required List<CropVariety> varieties,
  }) async {
    final storedCount = seedlingCount == 0 ? null : seedlingCount;
    _raisedBeds = _raisedBeds
        .map(
          (raisedBed) =>
              raisedBed.plotId == plotId && raisedBed.bedNumber == bedNumber
              ? raisedBed.withDetails(
                  seedlingCount: storedCount,
                  varieties: varieties,
                )
              : raisedBed,
        )
        .toList(growable: false);
  }
}

class _MemoryTaskRepository implements TaskRepository {
  _MemoryTaskRepository(this.raisedBeds);

  final List<RaisedBedRecord> raisedBeds;
  final List<PlotTaskRecord> tasks = [];

  @override
  Future<List<PlotTaskRecord>> getAllTasks() async {
    return List.unmodifiable(tasks);
  }

  @override
  Future<List<PlotTaskRecord>> getTasks(int plotId) async {
    return tasks.where((task) => task.plotId == plotId).toList(growable: false);
  }

  @override
  Future<PlotTaskRecord> createTask(TaskFormData data) async {
    final selectedNumbers = data.includesAllRaisedBeds
        ? const <int>[]
        : raisedBeds
              .where((raisedBed) => data.raisedBedIds.contains(raisedBed.id))
              .map((raisedBed) => raisedBed.bedNumber)
              .toList(growable: false);
    final task = PlotTaskRecord(
      id: tasks.length + 1,
      plotId: data.plotId,
      type: data.type,
      controlMethod: data.controlMethod,
      scheduledAt: data.scheduledAt,
      notes: data.notes,
      raisedBedNumbers: selectedNumbers,
      isCompleted: false,
      completedAt: null,
      cropCode: data.cropCode,
    );
    tasks.add(task);
    return task;
  }

  @override
  Future<PlotTaskRecord> updateTask({
    required int taskId,
    required TaskFormData data,
  }) async {
    final index = tasks.indexWhere((task) => task.id == taskId);
    final current = tasks[index];
    final typeChanged = current.type != data.type;
    final selectedNumbers = data.includesAllRaisedBeds
        ? const <int>[]
        : raisedBeds
              .where((raisedBed) => data.raisedBedIds.contains(raisedBed.id))
              .map((raisedBed) => raisedBed.bedNumber)
              .toList(growable: false);
    final updated = tasks[index].copyWith(
      type: data.type,
      controlMethod: data.controlMethod,
      controlProducts: typeChanged ? const [] : current.controlProducts,
      scheduledAt: data.scheduledAt,
      notes: data.notes,
      raisedBedNumbers: selectedNumbers,
    );
    tasks[index] = updated;
    return updated;
  }

  @override
  Future<PlotTaskRecord> markTaskCompleted({
    required int taskId,
    required int plotId,
  }) async {
    final index = tasks.indexWhere(
      (task) => task.id == taskId && task.plotId == plotId,
    );
    final updated = tasks[index].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    tasks[index] = updated;
    return updated;
  }

  @override
  Future<PlotTaskRecord> markTaskIncomplete({
    required int taskId,
    required int plotId,
  }) async {
    final index = tasks.indexWhere(
      (task) => task.id == taskId && task.plotId == plotId,
    );
    final current = tasks[index];
    final updated = PlotTaskRecord(
      id: current.id,
      plotId: current.plotId,
      type: current.type,
      controlMethod: current.controlMethod,
      controlProducts: current.controlProducts,
      scheduledAt: current.scheduledAt,
      notes: current.notes,
      raisedBedNumbers: current.raisedBedNumbers,
      isCompleted: false,
      completedAt: null,
      cropCode: current.cropCode,
    );
    tasks[index] = updated;
    return updated;
  }

  @override
  Future<PlotTaskRecord> updateControlMethod({
    required int taskId,
    required int plotId,
    required TaskControlMethod method,
    required List<TaskControlProduct> products,
  }) async {
    final index = tasks.indexWhere(
      (task) => task.id == taskId && task.plotId == plotId,
    );
    final updated = tasks[index].copyWith(
      controlMethod: method,
      controlProducts: method == TaskControlMethod.chemical
          ? products
          : const [],
    );
    tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask({required int taskId, required int plotId}) async {
    final index = tasks.indexWhere(
      (task) => task.id == taskId && task.plotId == plotId,
    );
    if (index < 0) throw StateError('Task does not exist.');
    tasks.removeAt(index);
  }
}

class _MemoryNotificationHistoryRepository
    implements NotificationHistoryRepository {
  _MemoryNotificationHistoryRepository(this.notifications);

  final List<TaskNotificationRecord> notifications;

  @override
  Future<void> cancelAllPending({DateTime? now}) async {}

  @override
  Future<void> cancelPendingForTask(int taskId, {DateTime? now}) async {}

  @override
  Future<List<TaskNotificationRecord>> getReceivedNotifications({
    DateTime? now,
  }) async => List.unmodifiable(notifications);

  @override
  Future<bool> hasUnreadNotifications({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    return notifications.any(
      (notification) =>
          !notification.isRead && !notification.receivedAt.isAfter(currentTime),
    );
  }

  @override
  Future<void> markAllAsRead({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    for (var index = 0; index < notifications.length; index++) {
      final notification = notifications[index];
      if (!notification.receivedAt.isAfter(currentTime)) {
        notifications[index] = notification.copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> deleteAllReceivedNotifications({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    notifications.removeWhere(
      (notification) => !notification.receivedAt.isAfter(currentTime),
    );
  }

  @override
  Future<void> deleteReceivedNotification(int notificationId) async {
    final index = notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index < 0) throw StateError('Notification does not exist.');
    notifications.removeAt(index);
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    final index = notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index < 0) throw StateError('Notification does not exist.');
    notifications[index] = notifications[index].copyWith(isRead: true);
  }

  @override
  Future<void> saveScheduledNotification({
    required int notificationId,
    required PlotTaskRecord task,
    required String title,
    required String message,
    required DateTime reminderAt,
  }) async {}
}
