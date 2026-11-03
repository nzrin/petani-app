import 'package:flutter/material.dart';
import 'package:petani/report/models/report_summary.dart';
import 'package:petani/report/repositories/report_repository.dart';

class ReportController extends ChangeNotifier {
  ReportController({required this.repository, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    final current = _now();
    selectedMonth = current.month - 1;
    data = ReportDashboardData.empty(current.year);
  }

  static const monthNames = <String>[
    'Januari',
    'Februari',
    'Mac',
    'April',
    'Mei',
    'Jun',
    'Julai',
    'Ogos',
    'September',
    'Oktober',
    'November',
    'Disember',
  ];

  static const shortMonthNames = <String>[
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

  final ReportRepository repository;
  final DateTime Function() _now;

  late ReportDashboardData data;
  late int selectedMonth;
  TaskReportStatus selectedStatus = TaskReportStatus.pending;
  bool isLoading = false;
  bool hasError = false;

  List<int> get values => data.taskStatistics.valuesFor(selectedStatus);
  int get selectedTotal => values[selectedMonth];
  String get selectedMonthName => monthNames[selectedMonth];
  int get year => data.taskStatistics.year;

  List<ReportSummary> get summaries => [
    ReportSummary(
      label: 'Jumlah Pokok',
      value: _formatNumber(data.totalPlants),
      caption: 'Direkodkan',
      icon: Icons.park_rounded,
    ),
    ReportSummary(
      label: 'Tugasan Selesai',
      value: _formatNumber(data.completedTasksThisMonth),
      caption: 'Bulan ini',
      icon: Icons.task_alt_rounded,
    ),
    ReportSummary(
      label: 'Jumlah Projek',
      value: _formatNumber(data.projectCount),
      caption: 'Projek aktif',
      icon: Icons.business_center_rounded,
    ),
    ReportSummary(
      label: 'Jumlah Plot',
      value: _formatNumber(data.plotCount),
      caption: 'Plot aktif',
      icon: Icons.grid_view_rounded,
    ),
  ];

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    hasError = false;
    notifyListeners();
    final current = _now();
    try {
      data = await repository.getDashboard(now: current, year: current.year);
    } catch (_) {
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectStatus(TaskReportStatus status) {
    if (selectedStatus == status) return;
    selectedStatus = status;
    notifyListeners();
  }

  void selectMonth(int month) {
    final next = month.clamp(0, 11);
    if (selectedMonth == next) return;
    selectedMonth = next;
    notifyListeners();
  }
}

String _formatNumber(int value) {
  final digits = '$value';
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
