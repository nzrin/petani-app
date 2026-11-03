import 'package:petani/core/database/app_database.dart';
import 'package:petani/report/models/report_summary.dart';

abstract interface class ReportRepository {
  Future<ReportDashboardData> getDashboard({
    required DateTime now,
    required int year,
  });
}

class SqliteReportRepository implements ReportRepository {
  const SqliteReportRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<ReportDashboardData> getDashboard({
    required DateTime now,
    required int year,
  }) async {
    final database = await _appDatabase.database;
    final plantRows = await database.rawQuery('''
      SELECT COALESCE(SUM(seedling_count), 0) AS total_plants
      FROM raised_beds
    ''');
    final plotRows = await database.rawQuery('''
      SELECT COUNT(*) AS plot_count
      FROM plots
    ''');
    final projectRows = await database.rawQuery('''
      SELECT COUNT(*) AS project_count
      FROM (
        SELECT LOWER(TRIM(project_name)) AS normalized_name
        FROM plots
        WHERE TRIM(project_name) != ''
        GROUP BY normalized_name
      )
    ''');

    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final completedRows = await database.rawQuery(
      '''
      SELECT COUNT(*) AS completed_count
      FROM farm_activities
      WHERE status = 'completed'
        AND completed_at >= ?
        AND completed_at < ?
      ''',
      [
        monthStart.toUtc().toIso8601String(),
        nextMonth.toUtc().toIso8601String(),
      ],
    );
    final taskRows = await database.query(
      'farm_activities',
      columns: ['scheduled_at', 'status'],
    );
    final plantingRows = await database.rawQuery(
      '''
      SELECT
        CAST(strftime('%m', plots.planted_at) AS INTEGER) AS month,
        COALESCE(SUM(raised_beds.seedling_count), 0) AS plant_count
      FROM plots
      LEFT JOIN raised_beds ON raised_beds.plot_id = plots.id
      WHERE plots.planted_at IS NOT NULL
        AND CAST(strftime('%Y', plots.planted_at) AS INTEGER) = ?
      GROUP BY month
      ''',
      [year],
    );

    final counts = {
      for (final status in TaskReportStatus.values)
        status: List<int>.filled(12, 0),
    };
    final scheduledTasks = List<int>.filled(12, 0);
    final completedTasks = List<int>.filled(12, 0);
    final today = DateTime(now.year, now.month, now.day);
    for (final row in taskRows) {
      final scheduledAt = DateTime.parse(
        row['scheduled_at'] as String,
      ).toLocal();
      if (scheduledAt.year != year) continue;

      scheduledTasks[scheduledAt.month - 1]++;
      if (row['status'] == 'completed') {
        completedTasks[scheduledAt.month - 1]++;
      }

      final status = row['status'] == 'completed'
          ? TaskReportStatus.completed
          : scheduledAt.isBefore(today)
          ? TaskReportStatus.overdue
          : TaskReportStatus.pending;
      counts[status]![scheduledAt.month - 1]++;
    }

    final plantedSeedlings = List<int>.filled(12, 0);
    for (final row in plantingRows) {
      final month = _readCount(row['month']);
      if (month < 1 || month > 12) continue;
      plantedSeedlings[month - 1] = _readCount(row['plant_count']);
    }

    return ReportDashboardData(
      totalPlants: _readCount(plantRows.single['total_plants']),
      projectCount: _readCount(projectRows.single['project_count']),
      plotCount: _readCount(plotRows.single['plot_count']),
      completedTasksThisMonth: _readCount(
        completedRows.single['completed_count'],
      ),
      taskStatistics: TaskStatisticsData(year: year, counts: counts),
      taskTrend: MonthlyTaskTrendData(
        scheduled: scheduledTasks,
        completed: completedTasks,
      ),
      plantingTrend: MonthlyPlantingData(plantCount: plantedSeedlings),
    );
  }
}

int _readCount(Object? value) => switch (value) {
  final int count => count,
  final num count => count.toInt(),
  _ => 0,
};
