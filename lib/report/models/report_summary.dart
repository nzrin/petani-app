import 'package:flutter/material.dart';

enum TaskReportStatus {
  pending(label: 'Belum Selesai'),
  completed(label: 'Selesai'),
  overdue(label: 'Lebih Masa');

  const TaskReportStatus({required this.label});

  final String label;
}

class TaskStatisticsData {
  const TaskStatisticsData({required this.year, required this.counts});

  factory TaskStatisticsData.empty(int year) {
    return TaskStatisticsData(
      year: year,
      counts: {
        for (final status in TaskReportStatus.values)
          status: List<int>.filled(12, 0),
      },
    );
  }

  final int year;
  final Map<TaskReportStatus, List<int>> counts;

  List<int> valuesFor(TaskReportStatus status) =>
      counts[status] ?? List<int>.filled(12, 0);
}

class MonthlyTaskTrendData {
  const MonthlyTaskTrendData({
    required this.scheduled,
    required this.completed,
  });

  factory MonthlyTaskTrendData.empty() {
    return MonthlyTaskTrendData(
      scheduled: List<int>.filled(12, 0),
      completed: List<int>.filled(12, 0),
    );
  }

  final List<int> scheduled;
  final List<int> completed;
}

class MonthlyPlantingData {
  const MonthlyPlantingData({required this.plantCount});

  factory MonthlyPlantingData.empty() {
    return MonthlyPlantingData(plantCount: List<int>.filled(12, 0));
  }

  final List<int> plantCount;
}

class ReportDashboardData {
  const ReportDashboardData({
    required this.totalPlants,
    required this.projectCount,
    required this.plotCount,
    required this.completedTasksThisMonth,
    required this.taskStatistics,
    required this.taskTrend,
    required this.plantingTrend,
  });

  factory ReportDashboardData.empty(int year) {
    return ReportDashboardData(
      totalPlants: 0,
      projectCount: 0,
      plotCount: 0,
      completedTasksThisMonth: 0,
      taskStatistics: TaskStatisticsData.empty(year),
      taskTrend: MonthlyTaskTrendData.empty(),
      plantingTrend: MonthlyPlantingData.empty(),
    );
  }

  final int totalPlants;
  final int projectCount;
  final int plotCount;
  final int completedTasksThisMonth;
  final TaskStatisticsData taskStatistics;
  final MonthlyTaskTrendData taskTrend;
  final MonthlyPlantingData plantingTrend;
}

class ReportSummary {
  const ReportSummary({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
}
