import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/home/models/plot_overview.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/home/models/task_schedule_record.dart';
import 'package:petani/project/models/task_form_data.dart';

abstract interface class HomeRepository {
  Future<List<PlotOverview>> getPlotOverviews({DateTime? now});

  Future<List<UpcomingTaskRecord>> getUpcomingTasks({DateTime? fromDate});

  Future<List<TaskScheduleRecord>> getScheduledTasksForMonth(DateTime month);
}

class SqliteHomeRepository implements HomeRepository {
  const SqliteHomeRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<PlotOverview>> getPlotOverviews({DateTime? now}) async {
    final database = await _appDatabase.database;
    final estimates = await _loadHarvestEstimates();
    final rows = await database.rawQuery('''
      SELECT
        plots.id AS plot_id,
        plots.project_name,
        plots.name AS plot_name,
        plots.variety_code,
        plots.planted_at,
        plots.created_at,
        crop_types.code AS crop_code,
        crop_types.display_name AS crop_name,
        crop_types.asset_path,
        COALESCE(SUM(raised_beds.seedling_count), 0) AS total_plants
      FROM plots
      INNER JOIN crop_types ON crop_types.id = plots.crop_type_id
      LEFT JOIN raised_beds ON raised_beds.plot_id = plots.id
      WHERE crop_types.is_available = 1
      GROUP BY plots.id, plots.project_name, plots.name,
        plots.variety_code, plots.planted_at, plots.created_at,
        crop_types.code, crop_types.display_name, crop_types.asset_path
      ORDER BY plots.created_at DESC, plots.id DESC
      LIMIT 5
      ''');

    final today = _dateOnly(now ?? DateTime.now());
    return rows
        .map((row) {
          final cropCode = row['crop_code'] as String;
          final estimate = estimates[cropCode];
          final plantedAtValue = row['planted_at'] as String?;
          final plantedAt = plantedAtValue == null
              ? null
              : DateTime.tryParse(plantedAtValue)?.toLocal();
          final totalPlants = row['total_plants'] as int? ?? 0;
          final estimatedHarvestAt =
              plantedAt == null || totalPlants == 0 || estimate == null
              ? null
              : _dateOnly(plantedAt).add(
                  Duration(
                    days: estimate.daysFor(row['variety_code'] as String?),
                  ),
                );

          return PlotOverview(
            plotId: row['plot_id'] as int,
            projectName: row['project_name'] as String,
            plotName: row['plot_name'] as String,
            cropCode: cropCode,
            cropName: row['crop_name'] as String,
            imagePath: row['asset_path'] as String? ?? '',
            totalPlants: totalPlants,
            daysToHarvest: estimate == null
                ? null
                : totalPlants == 0
                ? 0
                : estimatedHarvestAt
                      ?.difference(today)
                      .inDays
                      .clamp(0, 1 << 31),
            estimatedHarvestAt: estimatedHarvestAt,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<UpcomingTaskRecord>> getUpcomingTasks({
    DateTime? fromDate,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery('''
      SELECT
        farm_activities.id,
        farm_activities.plot_id,
        farm_activities.activity_type,
        farm_activities.scheduled_at,
        plots.project_name,
        plots.name AS plot_name,
        plots.location,
        crop_types.code AS crop_code,
        crop_types.display_name AS crop_name
      FROM farm_activities
      INNER JOIN plots ON plots.id = farm_activities.plot_id
      INNER JOIN crop_types ON crop_types.id = plots.crop_type_id
      WHERE farm_activities.status != 'completed'
      ORDER BY farm_activities.scheduled_at ASC, farm_activities.id DESC
    ''');

    final startDate = _dateOnly(fromDate ?? DateTime.now());
    return rows
        .map(
          (row) => UpcomingTaskRecord(
            id: row['id'] as int,
            plotId: row['plot_id'] as int,
            type: FarmTaskType.fromCode(row['activity_type'] as String),
            cropCode: row['crop_code'] as String,
            cropName: row['crop_name'] as String,
            projectName: row['project_name'] as String,
            plotName: row['plot_name'] as String,
            location: row['location'] as String? ?? '',
            scheduledAt: DateTime.parse(
              row['scheduled_at'] as String,
            ).toLocal(),
          ),
        )
        .where((task) => !_dateOnly(task.scheduledAt).isBefore(startDate))
        .toList(growable: false);
  }

  @override
  Future<List<TaskScheduleRecord>> getScheduledTasksForMonth(
    DateTime month,
  ) async {
    final database = await _appDatabase.database;
    final monthStart = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final rows = await database.rawQuery(
      '''
      SELECT
        farm_activities.id,
        farm_activities.plot_id,
        farm_activities.activity_type,
        farm_activities.scheduled_at,
        farm_activities.status,
        plots.project_name,
        plots.name AS plot_name,
        plots.location,
        crop_types.code AS crop_code,
        crop_types.display_name AS crop_name
      FROM farm_activities
      INNER JOIN plots ON plots.id = farm_activities.plot_id
      INNER JOIN crop_types ON crop_types.id = plots.crop_type_id
      WHERE farm_activities.scheduled_at >= ?
        AND farm_activities.scheduled_at < ?
      ORDER BY farm_activities.scheduled_at ASC, farm_activities.id ASC
      ''',
      [
        monthStart.toUtc().toIso8601String(),
        nextMonth.toUtc().toIso8601String(),
      ],
    );

    return rows
        .map(
          (row) => TaskScheduleRecord(
            id: row['id'] as int,
            plotId: row['plot_id'] as int,
            type: FarmTaskType.fromCode(row['activity_type'] as String),
            cropCode: row['crop_code'] as String,
            cropName: row['crop_name'] as String,
            projectName: row['project_name'] as String,
            plotName: row['plot_name'] as String,
            location: row['location'] as String? ?? '',
            scheduledAt: DateTime.parse(
              row['scheduled_at'] as String,
            ).toLocal(),
            isCompleted: row['status'] as String == 'completed',
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, _HarvestEstimate>> _loadHarvestEstimates() async {
    final source = await rootBundle.loadString(
      'assets/data/crop_harvest_estimates.json',
    );
    final document = jsonDecode(source) as Map<String, dynamic>;
    final crops = document['crops'] as List<dynamic>? ?? const [];
    return {
      for (final value in crops)
        if (value case final Map<String, dynamic> crop)
          crop['crop_code'] as String: _HarvestEstimate(
            estimateDays: crop['estimate_days'] as int,
            varietyEstimateDays:
                (crop['variety_estimate_days'] as Map<String, dynamic>? ??
                        const {})
                    .map((code, days) => MapEntry(code, days as int)),
          ),
    };
  }
}

class _HarvestEstimate {
  const _HarvestEstimate({
    required this.estimateDays,
    required this.varietyEstimateDays,
  });

  final int estimateDays;
  final Map<String, int> varietyEstimateDays;

  int daysFor(String? varietyCode) {
    return varietyEstimateDays[varietyCode] ?? estimateDays;
  }
}

DateTime _dateOnly(DateTime value) {
  final localValue = value.toLocal();
  return DateTime(localValue.year, localValue.month, localValue.day);
}
