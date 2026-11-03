import 'package:flutter/foundation.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';

enum RaisedBedFilter { all, unset, configured }

class PlotDetailController extends ChangeNotifier {
  PlotDetailController({
    required this.plot,
    required this.repository,
    required this.taskRepository,
  });

  final PlotRecord plot;
  final RaisedBedRepository repository;
  final TaskRepository taskRepository;

  List<RaisedBedRecord> raisedBeds = const [];
  List<PlotTaskRecord> tasks = const [];
  RaisedBedFilter filter = RaisedBedFilter.all;
  bool isLoading = false;
  bool isSaving = false;
  bool hasLoadError = false;
  bool isTaskLoading = false;
  bool isTaskSaving = false;
  bool hasTaskLoadError = false;

  Future<void> initialize() async {
    await Future.wait([loadRaisedBeds(), loadTasks()]);
  }

  List<RaisedBedRecord> get visibleRaisedBeds {
    return switch (filter) {
      RaisedBedFilter.all => raisedBeds,
      RaisedBedFilter.unset =>
        raisedBeds
            .where((raisedBed) => !raisedBed.isConfigured)
            .toList(growable: false),
      RaisedBedFilter.configured =>
        raisedBeds
            .where((raisedBed) => raisedBed.isConfigured)
            .toList(growable: false),
    };
  }

  int get configuredCount =>
      raisedBeds.where((raisedBed) => raisedBed.isConfigured).length;

  int get totalSeedlings => raisedBeds.fold(
    0,
    (total, raisedBed) => total + (raisedBed.seedlingCount ?? 0),
  );

  int get averageSeedlings {
    if (configuredCount == 0) return 0;
    return (totalSeedlings / configuredCount).round();
  }

  Future<void> loadRaisedBeds() async {
    if (isLoading) return;
    isLoading = true;
    hasLoadError = false;
    notifyListeners();
    try {
      raisedBeds = await repository.getRaisedBeds(plot.id);
    } on Exception {
      hasLoadError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks() async {
    if (isTaskLoading) return;
    isTaskLoading = true;
    hasTaskLoadError = false;
    notifyListeners();
    try {
      tasks = await taskRepository.getTasks(plot.id);
    } on Exception {
      hasTaskLoadError = true;
    } finally {
      isTaskLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask(TaskFormData data) async {
    if (isTaskSaving) return false;
    isTaskSaving = true;
    notifyListeners();
    try {
      final task = await taskRepository.createTask(data);
      tasks = [...tasks, task]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return true;
    } on Exception {
      return false;
    } finally {
      isTaskSaving = false;
      notifyListeners();
    }
  }

  void replaceTask(PlotTaskRecord updatedTask) {
    tasks =
        tasks
            .map((task) => task.id == updatedTask.id ? updatedTask : task)
            .toList(growable: false)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    notifyListeners();
  }

  void removeTask(int taskId) {
    tasks = tasks.where((task) => task.id != taskId).toList(growable: false);
    notifyListeners();
  }

  void selectFilter(RaisedBedFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  Future<bool> saveRaisedBedDetails({
    required RaisedBedRecord raisedBed,
    required int seedlingCount,
    required List<CropVariety> varieties,
  }) async {
    if (isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      await repository.saveRaisedBedDetails(
        plotId: plot.id,
        bedNumber: raisedBed.bedNumber,
        seedlingCount: seedlingCount,
        varieties: varieties,
      );
      final storedCount = seedlingCount == 0 ? null : seedlingCount;
      raisedBeds = raisedBeds
          .map(
            (item) => item.bedNumber == raisedBed.bedNumber
                ? item.withDetails(
                    seedlingCount: storedCount,
                    varieties: varieties,
                  )
                : item,
          )
          .toList(growable: false);
      return true;
    } on Exception {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> saveBulkRaisedBedDetails({
    required int seedlingCount,
    required bool onlyUnset,
    required List<CropVariety> varieties,
  }) async {
    if (isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      await repository.saveBulkRaisedBedDetails(
        plotId: plot.id,
        seedlingCount: seedlingCount,
        onlyUnset: onlyUnset,
        varieties: varieties,
      );
      final storedCount = seedlingCount == 0 ? null : seedlingCount;
      raisedBeds = raisedBeds
          .map(
            (item) => onlyUnset && item.isConfigured
                ? item
                : item.withDetails(
                    seedlingCount: storedCount,
                    varieties: varieties,
                  ),
          )
          .toList(growable: false);
      return true;
    } on Exception {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
