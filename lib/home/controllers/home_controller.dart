import 'package:flutter/foundation.dart';
import 'package:petani/home/models/plot_overview.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/home/repositories/home_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController({required this.repository});

  final HomeRepository repository;

  List<PlotOverview> plotOverviews = const [];
  List<UpcomingTaskRecord> tasks = const [];
  bool isLoading = false;
  bool hasLoadError = false;
  int _loadRequest = 0;

  List<UpcomingTaskRecord> get previewTasks =>
      tasks.take(3).toList(growable: false);

  Future<void> loadUpcomingTasks() async {
    final request = ++_loadRequest;
    isLoading = true;
    hasLoadError = false;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        repository.getUpcomingTasks(),
        repository.getPlotOverviews(),
      ]);
      if (request == _loadRequest) {
        tasks = results[0] as List<UpcomingTaskRecord>;
        plotOverviews = results[1] as List<PlotOverview>;
      }
    } catch (_) {
      if (request == _loadRequest) hasLoadError = true;
    } finally {
      if (request == _loadRequest) {
        isLoading = false;
        notifyListeners();
      }
    }
  }
}
