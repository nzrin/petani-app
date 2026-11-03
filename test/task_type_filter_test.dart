import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/project/controllers/task_form_controller.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/views/task_form_sheet.dart';
import 'package:petani/project/controllers/project_form_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ProductSans')
      ..addFont(rootBundle.load('assets/fonts/ProductSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ProductSans-Bold.ttf'));
    await loader.load();
  });

  test('crop defaults include relevant specialist tasks', () {
    for (final crop in [
      'pineapple',
      'coconut',
      'banana',
      'oil_palm',
      'rubber_tree',
      'ginger',
      'rice',
      'torch_ginger',
    ]) {
      final controller = TaskFormController(
        plotId: 1,
        cropCode: crop,
        raisedBeds: const [],
      );
      addTearDown(controller.dispose);
      final types = controller.visibleTaskTypes;
      expect(controller.showAllTaskTypes, isFalse);
      expect(types.contains(FarmTaskType.rubberTapping), crop == 'rubber_tree');
      expect(types.contains(FarmTaskType.flowerInduction), crop == 'pineapple');
      expect(types.contains(FarmTaskType.bunchBagging), crop == 'banana');
      expect(
        types.contains(FarmTaskType.pruning),
        !['pineapple', 'ginger', 'rice'].contains(crop),
      );
      expect(types.contains(FarmTaskType.ploughing), crop == 'rice');
      expect(types.contains(FarmTaskType.seedSowing), crop == 'rice');
      expect(types, contains(FarmTaskType.irrigation));
      controller.toggleTaskTypes();
      expect(controller.visibleTaskTypes, FarmTaskType.values);
    }
  });

  test('returning to defaults preserves the selected task and form data', () {
    final controller = TaskFormController(
      plotId: 1,
      cropCode: 'banana',
      raisedBeds: const [],
      initialDate: DateTime(2026, 11, 4),
    );
    addTearDown(controller.dispose);
    controller.toggleTaskTypes();
    controller.selectType(FarmTaskType.seedHarvest);
    controller.setNotes('Benih untuk plot baharu');
    controller.toggleTaskTypes();
    expect(controller.visibleTaskTypes, contains(FarmTaskType.seedHarvest));
    final result = controller.buildResult();
    expect(result.type, FarmTaskType.seedHarvest);
    expect(result.notes, 'Benih untuk plot baharu');
    expect(result.scheduledAt, DateTime(2026, 11, 4, 7, 30));
    controller.selectType(FarmTaskType.bunchBagging);
    expect(
      controller.visibleTaskTypes,
      isNot(contains(FarmTaskType.seedHarvest)),
    );
  });

  test(
    'new planting tasks follow crop defaults and remain available in all tasks',
    () {
      const newTypes = {
        FarmTaskType.planting,
        FarmTaskType.bedPreparation,
        FarmTaskType.supportInstallation,
        FarmTaskType.mulching,
        FarmTaskType.manualPollination,
        FarmTaskType.fruitThinning,
        FarmTaskType.vineLifting,
      };
      for (final crop in ProjectFormController.supportedCrops.keys) {
        final controller = TaskFormController(
          plotId: 1,
          cropCode: crop,
          raisedBeds: const [],
        );
        addTearDown(controller.dispose);
        final types = controller.visibleTaskTypes;
        expect(types, contains(FarmTaskType.planting));
        expect(
          types.contains(FarmTaskType.manualPollination),
          crop == 'rock_melon',
        );
        expect(types.contains(FarmTaskType.fruitThinning), crop == 'durian');
        expect(
          types.contains(FarmTaskType.vineLifting),
          crop == 'sweet_potato',
        );
        expect(
          types.contains(FarmTaskType.supportInstallation),
          ['cucumber', 'rock_melon', 'chilli', 'eggplant'].contains(crop),
        );
        expect(
          types.contains(FarmTaskType.bedPreparation),
          [
            'pineapple',
            'ginger',
            'cassava',
            'sweet_potato',
            'watermelon',
            'rock_melon',
            'strawberry',
            'chilli',
            'cucumber',
            'eggplant',
          ].contains(crop),
        );
        controller.toggleTaskTypes();
        expect(controller.visibleTaskTypes, containsAll(newTypes));
        for (final type in newTypes) {
          expect(FarmTaskType.fromCode(type.code), type);
          expect(type.supportsControlMethod, isFalse);
          controller.selectType(type);
          expect(controller.buildResult().type, type);
        }
      }
    },
  );

  test('editing a task outside crop defaults opens all types', () {
    final initial = PlotTaskRecord(
      id: 2,
      plotId: 1,
      cropCode: 'banana',
      type: FarmTaskType.seedHarvest,
      scheduledAt: DateTime(2026, 11, 4, 9),
      notes: 'Kekalkan nota',
      raisedBedNumbers: const [],
      isCompleted: false,
      completedAt: null,
    );
    final controller = TaskFormController(
      plotId: 1,
      cropCode: 'banana',
      raisedBeds: const [],
      initialTask: initial,
    );
    addTearDown(controller.dispose);
    expect(controller.showAllTaskTypes, isTrue);
    expect(controller.visibleTaskTypes, contains(initial.type));
    expect(controller.buildResult().type, initial.type);
    expect(controller.buildResult().scheduledAt, initial.scheduledAt);
  });

  test('every task has a bundled PNG for cards and notifications', () async {
    for (final type in FarmTaskType.values) {
      final data = await rootBundle.load(type.imagePath);
      expect(data.buffer.asUint8List(data.offsetInBytes, 8), [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ], reason: type.imagePath);
    }
  });

  for (final crop in [
    'banana',
    'rice',
    'torch_ginger',
    'rock_melon',
    'durian',
    'sweet_potato',
  ]) {
    for (final width in [320.0, 390.0]) {
      testWidgets('$crop task tabs and steps work at width $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: TaskFormSheet(
                plotId: 1,
                cropCode: crop,
                raisedBeds: const [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        int itemCount() =>
            (tester
                        .widget<GridView>(
                          find.byKey(const Key('task-type-grid')),
                        )
                        .childrenDelegate
                    as SliverChildBuilderDelegate)
                .childCount!;
        expect(itemCount(), FarmTaskType.suggestedForCrop(crop).length);
        expect(find.text('Semua Tugasan'), findsOneWidget);
        final suitableTab = find.byKey(const Key('task-types-suitable-tab'));
        final allTab = find.byKey(const Key('task-types-all-tab'));
        expect(find.text('Tugasan Sesuai'), findsOneWidget);
        final style = tester.widget<TextButton>(suitableTab).style!;
        expect(style.backgroundColor!.resolve({}), AppColors.primaryAction);
        expect(style.foregroundColor!.resolve({}), Colors.white);
        await tester.tap(suitableTab);
        await tester.pumpAndSettle();
        expect(itemCount(), FarmTaskType.suggestedForCrop(crop).length);
        expect(
          tester
              .widget<AppButton>(find.byKey(const Key('task-next-button')))
              .onPressed,
          isNull,
        );
        expect(find.byKey(const Key('task-notes-field')), findsNothing);
        expect(find.byKey(const Key('save-task-button')), findsNothing);
        await tester.tap(allTab);
        await tester.pumpAndSettle();
        expect(itemCount(), FarmTaskType.values.length);
        expect(find.text('Tugasan Sesuai'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final allStyle = tester.widget<TextButton>(allTab).style!;
        expect(allStyle.backgroundColor!.resolve({}), AppColors.primaryAction);
        expect(allStyle.foregroundColor!.resolve({}), Colors.white);
        await tester.tap(allTab);
        await tester.pumpAndSettle();
        expect(itemCount(), FarmTaskType.values.length);
        await tester.tap(suitableTab);
        await tester.pumpAndSettle();
        expect(itemCount(), FarmTaskType.suggestedForCrop(crop).length);
        expect(tester.takeException(), isNull);
        final selectedType = switch (crop) {
          'rice' => 'seed_sowing',
          'rock_melon' => 'manual_pollination',
          'durian' => 'fruit_thinning',
          'sweet_potato' => 'vine_lifting',
          _ => 'fungus_control',
        };
        final card = find.byKey(Key('task-type-$selectedType'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pump();
        await tester.tap(find.byKey(const Key('task-next-button')));
        await tester.pumpAndSettle();
        expect(find.text('Langkah 2 daripada 2'), findsOneWidget);
        expect(
          find.text(switch (crop) {
            'rice' => 'Petak Terlibat',
            'rock_melon' || 'sweet_potato' => 'Batas Terlibat',
            _ => 'Baris Terlibat',
          }),
          findsOneWidget,
        );
        expect(find.byKey(const Key('task-type-grid')), findsNothing);
        expect(find.byKey(const Key('task-date-button')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('task-notes-field')));
        await tester.enterText(
          find.byKey(const Key('task-notes-field')),
          'Nota kekal',
        );
        await tester.tap(find.byKey(const Key('task-back-button')));
        await tester.pumpAndSettle();
        expect(find.text('Langkah 1 daripada 2'), findsOneWidget);
        expect(find.byKey(const Key('task-type-grid')), findsOneWidget);
        await tester.tap(find.byKey(const Key('task-next-button')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('task-notes-field')))
              .controller!
              .text,
          'Nota kekal',
        );
        expect(
          tester
              .widget<AppButton>(find.byKey(const Key('save-task-button')))
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
