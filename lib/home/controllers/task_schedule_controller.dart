import 'package:flutter/foundation.dart';
import 'package:petani/home/models/task_schedule_record.dart';
import 'package:petani/home/repositories/home_repository.dart';

class TaskScheduleController extends ChangeNotifier {
  TaskScheduleController({required this.repository, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    final today = _dateOnly(_now());
    selectedMonth = DateTime(today.year, today.month);
  }

  final HomeRepository repository;
  final DateTime Function() _now;

  late DateTime selectedMonth;
  List<TaskScheduleRecord> tasks = const [];
  String query = '';
  bool isLoading = false;
  bool hasLoadError = false;
  int _loadRequest = 0;

  DateTime get today => _dateOnly(_now());

  List<TaskScheduleRecord> get visibleTasks =>
      tasks.where((task) => task.matches(query)).toList(growable: false);

  List<TaskScheduleRecord> tasksForDate(DateTime date) => visibleTasks
      .where((task) => _isSameDay(task.scheduledAt, date))
      .toList(growable: false);

  Future<void> load() async {
    final request = ++_loadRequest;
    isLoading = true;
    hasLoadError = false;
    notifyListeners();
    try {
      final loaded = await repository.getScheduledTasksForMonth(selectedMonth);
      if (request == _loadRequest) tasks = loaded;
    } catch (_) {
      if (request == _loadRequest) hasLoadError = true;
    } finally {
      if (request == _loadRequest) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> showPreviousMonth() => _changeMonth(-1);

  Future<void> showNextMonth() => _changeMonth(1);

  void setQuery(String value) {
    if (query == value) return;
    query = value;
    notifyListeners();
  }

  Future<void> _changeMonth(int offset) async {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + offset);
    query = '';
    await load();
  }
}

DateTime _dateOnly(DateTime value) {
  final localValue = value.toLocal();
  return DateTime(localValue.year, localValue.month, localValue.day);
}

bool _isSameDay(DateTime left, DateTime right) {
  final localLeft = left.toLocal();
  final localRight = right.toLocal();
  return localLeft.year == localRight.year &&
      localLeft.month == localRight.month &&
      localLeft.day == localRight.day;
}
