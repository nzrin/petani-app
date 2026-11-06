import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/home/models/plot_overview.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/project/controllers/project_form_controller.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/views/project_form_sheet.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/models/crop_harvest_estimate.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CropHarvestCatalog catalog;
  late Directory databaseDirectory;

  setUpAll(() async {
    catalog = await CropHarvestCatalog.load();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseDirectory = await Directory.systemTemp.createTemp(
      'petani-harvest-',
    );
    await databaseFactory.setDatabasesPath(databaseDirectory.path);
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    await databaseDirectory.delete(recursive: true);
  });

  test('every enabled UI and database crop has a sourced estimate', () async {
    final uiCodes = CropSelectionController.cropOptions
        .where((crop) => crop.isAvailable)
        .map((crop) => crop.code)
        .toSet();
    final db = await AppDatabase.instance.database;
    final rows = await db.query('crop_types', where: 'is_available = 1');
    final dbCodes = rows.map((row) => row['code'] as String).toSet();
    expect(dbCodes, uiCodes);
    expect(
      () => catalog.requireCoverage({...uiCodes, ...dbCodes}),
      returnsNormally,
    );
    for (final code in uiCodes) {
      final controller = ProjectFormController(cropCode: code);
      final knownVarieties = controller.availableVarieties.map((v) => v.code);
      expect(
        knownVarieties,
        containsAll(catalog[code]!.varietyEstimateDays.keys),
        reason: '$code override keys must match selectable varieties',
      );
      controller.dispose();
    }
    expect(
      () => catalog.requireCoverage([...uiCodes, 'future_crop']),
      throwsStateError,
    );
  });

  test('new crop metadata integrates without adding calculation branches', () {
    final document =
        jsonDecode(File(CropHarvestCatalog.assetPath).readAsStringSync())
            as Map<String, dynamic>;
    final entries = document['crops'] as List<dynamic>;
    entries.add({
      ...entries.first as Map<String, dynamic>,
      'crop_code': 'future_crop',
      'estimate_days': 400,
      'variety_estimate_days': <String, int>{},
    });
    final expanded = CropHarvestCatalog.fromJson(jsonEncode(document));
    expanded.requireCoverage(['future_crop']);
    expect(
      expanded['future_crop']!.harvestDate(
        plantedAt: DateTime(2026, 1, 1),
        totalPlants: 1,
      ),
      DateTime(2027, 2, 5),
    );
    expect(expanded['unknown_crop'], isNull);
  });

  test('invalid or duplicated catalog entries are rejected', () {
    Map<String, dynamic> document() =>
        jsonDecode(File(CropHarvestCatalog.assetPath).readAsStringSync())
            as Map<String, dynamic>;
    final negative = document();
    negative['crops'][0]['estimate_days'] = -1;
    expect(
      () => CropHarvestCatalog.fromJson(jsonEncode(negative)),
      throwsFormatException,
    );
    final duplicate = document();
    (duplicate['crops'] as List).add(duplicate['crops'][0]);
    expect(
      () => CropHarvestCatalog.fromJson(jsonEncode(duplicate)),
      throwsFormatException,
    );
  });

  test('known varieties override crop defaults; mixed plots use earliest', () {
    expect(catalog['pineapple']!.daysFor('AC1'), 365);
    expect(catalog['coconut']!.daysFor('CN6'), 1095);
    expect(catalog['banana']!.daysFor('MP3'), 243);
    expect(catalog['banana']!.daysFor('MP14'), 395);
    expect(catalog['rice']!.daysFor('MR CL3'), 99);
    expect(catalog['rice']!.daysFor('MRQ 104'), 119);
    expect(catalog['rice']!.daysFor('unknown'), 111);
    expect(catalog['banana']!.daysForVarieties(['MP14', 'MP3']), 243);
    expect(catalog['banana']!.daysForVarieties(['MP3', 'MP14']), 243);
  });

  test('calendar dates, leap year, missing inputs and elapsed estimates', () {
    final corn = catalog['corn']!;
    final harvest = corn.harvestDate(
      plantedAt: DateTime(2024, 1, 1, 23, 59),
      totalPlants: 1,
    );
    expect(harvest, DateTime(2024, 3, 11));
    expect(
      CropHarvestEstimate.remainingDays(harvest, DateTime(2024, 3, 10, 23, 59)),
      1,
    );
    expect(
      CropHarvestEstimate.remainingDays(harvest, DateTime(2024, 3, 11)),
      0,
    );
    expect(CropHarvestEstimate.remainingDays(harvest, DateTime(2025)), 0);
    expect(CropHarvestEstimate.remainingDays(null, DateTime(2024)), isNull);
    expect(corn.harvestDate(plantedAt: null, totalPlants: 1), isNull);
    expect(corn.harvestDate(plantedAt: DateTime(2024), totalPlants: 0), isNull);
    expect(
      corn.harvestDate(plantedAt: DateTime(2024), totalPlants: -1),
      isNull,
    );
    final future = corn.harvestDate(plantedAt: DateTime(2027), totalPlants: 1);
    expect(
      CropHarvestEstimate.remainingDays(future, DateTime(2026, 12, 31)),
      71,
    );
  });

  test(
    'Home calculates all active crops and handles mixed and legacy records',
    () async {
      final db = await AppDatabase.instance.database;
      final projects = SqliteProjectRepository(AppDatabase.instance);
      final home = SqliteHomeRepository(AppDatabase.instance);
      final plantedAt = DateTime(2026, 11, 1);
      final now = DateTime(2026, 11, 6, 23);
      for (final crop in CropSelectionController.cropOptions.where(
        (c) => c.isAvailable,
      )) {
        final form = ProjectFormController(cropCode: crop.code);
        final varieties = form.availableVarieties;
        final id = await projects.createProject(
          ProjectFormData(
            cropCode: crop.code,
            projectName: 'Harvest ${crop.code}',
            location: 'Johor',
            plotName: 'Plot',
            varieties: varieties,
            raisedBedCount: 2,
            plantedAt: plantedAt,
          ),
        );
        await db.update(
          'raised_beds',
          {'seedling_count': 10},
          where: 'plot_id = ?',
          whereArgs: [id],
        );
        var overview = (await home.getPlotOverviews(
          now: now,
        )).singleWhere((p) => p.plotId == id);
        final expectedDays = varieties
            .map((v) => catalog[crop.code]!.daysFor(v.code))
            .reduce((a, b) => a < b ? a : b);
        expect(
          overview.totalPlants,
          20,
          reason: 'Variety joins must not multiply plant totals',
        );
        expect(overview.daysToHarvest, expectedDays - 5, reason: crop.code);
        expect(
          overview.estimatedHarvestAt,
          DateTime(2026, 11, 1 + expectedDays),
        );
        expect(overview.hasMixedVarieties, varieties.length > 1);
        expect(overview.harvestEstimate, isNotNull);
        // Old databases can have only the primary variety on plots.
        await db.delete(
          'plot_varieties',
          where: 'plot_id = ?',
          whereArgs: [id],
        );
        overview = (await home.getPlotOverviews(
          now: now,
        )).singleWhere((p) => p.plotId == id);
        expect(
          overview.daysToHarvest,
          catalog[crop.code]!.daysFor(varieties.first.code) - 5,
        );
        await db.update(
          'plots',
          {'planted_at': null},
          where: 'id = ?',
          whereArgs: [id],
        );
        overview = (await home.getPlotOverviews(
          now: now,
        )).singleWhere((p) => p.plotId == id);
        expect(overview.daysToHarvest, isNull);
        await db.update(
          'plots',
          {'planted_at': 'invalid'},
          where: 'id = ?',
          whereArgs: [id],
        );
        overview = (await home.getPlotOverviews(
          now: now,
        )).singleWhere((p) => p.plotId == id);
        expect(overview.estimatedHarvestAt, isNull);
        await projects.deletePlot(id);
        form.dispose();
      }
    },
  );

  test(
    'labels distinguish tapping and elapsed estimates from confirmed harvest',
    () {
      PlotOverview overview(String crop, int? days) => PlotOverview(
        plotId: 1,
        projectName: 'Test',
        plotName: 'Plot',
        cropCode: crop,
        cropName: crop,
        imagePath: '',
        totalPlants: 1,
        daysToHarvest: days,
        estimatedHarvestAt: null,
        harvestEstimate: catalog[crop],
      );
      expect(
        overview('rubber_tree', 10).harvestLabel,
        'ke anggaran mula menoreh',
      );
      expect(overview('durian', 10).harvestLabel, 'ke anggaran hasil pertama');
      expect(
        overview('rice', 0).harvestLabel,
        'anggaran tuaian pertama telah tiba',
      );
      expect(
        overview('rice', null).harvestLabel,
        'anggaran tuaian belum tersedia',
      );
      expect(
        overview('rubber_tree', 1).harvestExplanation,
        contains('lilitan'),
      );
    },
  );

  testWidgets('planting date explains the crop-specific starting point', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectFormSheet(
            cropCode: 'rice',
            fixedProject: const ExistingProjectSuggestion(
              name: 'Sawah',
              location: 'Kedah',
            ),
            initialData: ProjectFormData(
              cropCode: 'rice',
              projectName: 'Sawah',
              plotName: 'Petak',
              location: 'Kedah',
              varieties: const [CropVariety(code: 'MR CL3', name: 'MR CL3')],
              raisedBedCount: 1,
              plantedAt: DateTime(2026, 11, 1),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Navigate to the details step when editing a plot.
    final next = find.text('Seterusnya');
    for (
      var i = 0;
      i < 4 &&
          find
              .byKey(const Key('harvest-planting-date-help'))
              .evaluate()
              .isEmpty;
      i++
    ) {
      if (next.evaluate().isEmpty) break;
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    // The cached asset future was resolved in setUpAll's real async zone.
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.text(catalog['rice']!.plantingDateHelp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
