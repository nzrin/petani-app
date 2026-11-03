import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/project/controllers/project_form_controller.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/crop_selection_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const active = {
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
};
const coming = {
  'lime',
  'pandan',
  'lemongrass',
  'tomato',
  'turmeric',
  'calamansi',
  'kesum',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory databaseDirectory;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseDirectory = await Directory.systemTemp.createTemp('petani-crops-');
    await databaseFactory.setDatabasesPath(databaseDirectory.path);
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    await databaseDirectory.delete(recursive: true);
  });

  test(
    'version 17 upgrade preserves farm records and enables only requested crops',
    () async {
      var database = await AppDatabase.instance.database;
      final projects = SqliteProjectRepository(AppDatabase.instance);
      final beds = SqliteRaisedBedRepository(AppDatabase.instance);
      final tasks = SqliteTaskRepository(AppDatabase.instance);
      final legacyId = await projects.createProject(
        ProjectFormData(
          cropCode: 'pineapple',
          projectName: 'Projek Lama',
          location: 'Johor',
          plotName: 'Plot Lama',
          varieties: const [CropVariety(code: 'AC1', name: 'Moris')],
          raisedBedCount: 2,
          plantedAt: DateTime(2026, 11, 3),
        ),
      );
      final legacyBeds = await beds.getRaisedBeds(legacyId);
      await tasks.createTask(
        TaskFormData(
          plotId: legacyId,
          type: FarmTaskType.fertilizing,
          includesAllRaisedBeds: false,
          raisedBedIds: {legacyBeds.first.id},
          scheduledAt: DateTime(2026, 11, 5, 8),
          notes: 'Kekalkan nota ini',
        ),
      );
      for (final code in {...active, ...coming}) {
        await database.delete(
          'crop_types',
          where: 'code = ?',
          whereArgs: [code],
        );
      }
      final originalCrops = await database.query('crop_types', orderBy: 'id');
      const tables = [
        'plots',
        'raised_beds',
        'plot_varieties',
        'farm_activities',
        'farm_activity_raised_beds',
      ];
      final before = {
        for (final table in tables) table: await database.query(table),
      };
      await database.setVersion(17);
      await AppDatabase.instance.close();
      database = await AppDatabase.instance.database;
      expect(await database.getVersion(), AppDatabase.databaseVersion);
      for (final table in tables) {
        expect(await database.query(table), before[table], reason: table);
      }
      for (final crop in originalCrops) {
        expect(
          (await database.query(
            'crop_types',
            where: 'id = ?',
            whereArgs: [crop['id']],
          )).single,
          crop,
        );
      }
      final cropRows = await database.query('crop_types');
      expect(cropRows, hasLength(25));
      expect(cropRows.where((row) => row['is_available'] == 1), hasLength(18));
      for (final option in CropSelectionController.cropOptions) {
        final row = cropRows.singleWhere((row) => row['code'] == option.code);
        expect(row['display_name'], option.name);
        expect(row['is_available'], option.isAvailable ? 1 : 0);
        expect(
          ProjectFormController.supportedCrops.containsKey(option.code),
          option.isAvailable,
        );
      }

      // Running the migration against existing catalogue rows must keep their IDs.
      final ids = await database.query(
        'crop_types',
        columns: ['id', 'code'],
        orderBy: 'id',
      );
      await database.setVersion(17);
      await AppDatabase.instance.close();
      database = await AppDatabase.instance.database;
      expect(
        await database.query(
          'crop_types',
          columns: ['id', 'code'],
          orderBy: 'id',
        ),
        ids,
      );

      for (final code in active) {
        final form = ProjectFormController(cropCode: code);
        form.projectNameController.text = 'Projek $code';
        form.locationController.text = 'Johor';
        form.plotNameController.text = 'Plot $code';
        form.currentStep = 3;
        expect(form.canContinue, isFalse);
        form.toggleVariety(form.availableVarieties.first);
        expect(form.canContinue, isTrue);
        final data = form.buildResult();
        final id = await projects.createProject(data);
        final edit = ProjectFormController(initialData: data);
        expect(edit.selectedVarieties, data.varieties.toSet());
        await projects.updatePlot(plotId: id, data: data);
        final rows = await beds.getRaisedBeds(id);
        final saved = await tasks.createTask(
          TaskFormData(
            plotId: id,
            cropCode: code,
            type: FarmTaskType.fruitHarvest,
            includesAllRaisedBeds: true,
            raisedBedIds: {},
            scheduledAt: DateTime(2026, 11, 6, 8),
            notes: 'Hasil $code',
          ),
        );
        expect(rows, hasLength(1));
        expect(saved.cropCode, code);
        expect((await tasks.getTasks(id)).single.notes, 'Hasil $code');
        final overview = (await SqliteHomeRepository(
          AppDatabase.instance,
        ).getPlotOverviews()).singleWhere((plot) => plot.plotId == id);
        expect(overview.estimatedHarvestAt, isNull);
        final types = FarmTaskType.suggestedForCrop(code);
        expect(types, contains(FarmTaskType.fruitHarvest));
        expect(types, isNot(contains(FarmTaskType.rubberTapping)));
        expect(types, isNot(contains(FarmTaskType.bunchBagging)));
        expect(types, isNot(contains(FarmTaskType.flowerInduction)));
        form.dispose();
        edit.dispose();
      }
      for (final code in coming) {
        expect(
          () => projects.createProject(
            ProjectFormData(
              cropCode: code,
              projectName: 'Belum tersedia',
              location: 'Johor',
              plotName: code,
              varieties: const [CropVariety(code: 'test', name: 'Test')],
              raisedBedCount: 1,
              plantedAt: DateTime(2026, 11, 3),
            ),
          ),
          throwsStateError,
        );
      }
    },
  );

  test(
    'every new crop and produce image is bundled with transparent corners',
    () async {
      for (final code in {...active, ...coming}) {
        for (final folder in ['crops', 'seeds']) {
          final path = 'assets/images/$folder/$code.png';
          final bytes = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;
          expect(image.width, 500, reason: path);
          expect(image.height, 500, reason: path);
          final rgba = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (final pixel in [0, 499, 499 * 500, 500 * 500 - 1]) {
            // Allow negligible alpha noise from resampling painted cutout edges.
            expect(
              rgba.getUint8(pixel * 4 + 3),
              lessThanOrEqualTo(5),
              reason: path,
            );
          }
          image.dispose();
          codec.dispose();
        }
      }
    },
  );

  testWidgets(
    'coming soon crops are dimmed and cannot be selected in grid or list',
    (tester) async {
      final controller = CropSelectionController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: CropSelectionSheet(controller: controller)),
        ),
      );
      for (final grid in [true, false]) {
        controller.setShowGrid(grid);
        for (final code in coming) {
          final crop = CropSelectionController.cropOptions.singleWhere(
            (crop) => crop.code == code,
          );
          final previousSelection = controller.selectedCrop;
          await tester.enterText(
            find.byKey(const Key('crop-search-field')),
            crop.name,
          );
          await tester.pumpAndSettle();
          expect(find.text('Akan Datang'), findsOneWidget);
          final tile = find.byKey(Key('crop-tile-${crop.name}'));
          expect(
            tester
                .widget<InkWell>(
                  find.descendant(of: tile, matching: find.byType(InkWell)),
                )
                .onTap,
            isNull,
          );
          if (!grid) {
            expect(
              tester
                  .widget<Opacity>(
                    find.descendant(of: tile, matching: find.byType(Opacity)),
                  )
                  .opacity,
              0.38,
            );
          }
          await tester.tap(tile);
          controller.selectCrop(crop);
          await tester.pumpAndSettle();
          expect(controller.selectedCrop, same(previousSelection));
          expect(
            tester
                .widget<AppButton>(find.byKey(const Key('teruskan-button')))
                .onPressed,
            isNull,
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );
}
