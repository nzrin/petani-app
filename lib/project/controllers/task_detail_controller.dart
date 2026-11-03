import 'package:flutter/foundation.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/models/task_control_product.dart';
import 'package:petani/project/repositories/task_repository.dart';

class TaskDetailController extends ChangeNotifier {
  TaskDetailController({required this.task, required this.repository});

  PlotTaskRecord task;
  final TaskRepository repository;
  bool isSaving = false;

  Future<bool> updateTask(TaskFormData data) async {
    if (isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      task = await repository.updateTask(taskId: task.id, data: data);
      return true;
    } on Exception {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> markCompleted() async {
    if (isSaving || task.isCompleted) return false;
    isSaving = true;
    notifyListeners();
    try {
      task = await repository.markTaskCompleted(
        taskId: task.id,
        plotId: task.plotId,
      );
      return true;
    } on Exception {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateControlMethod({
    required TaskControlMethod method,
    List<TaskControlProduct> products = const [],
  }) async {
    if (isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      task = await repository.updateControlMethod(
        taskId: task.id,
        plotId: task.plotId,
        method: method,
        products: products,
      );
      return true;
    } on Exception {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> markIncomplete() async {
    if (isSaving || !task.isCompleted) return false;
    isSaving = true;
    notifyListeners();
    try {
      task = await repository.markTaskIncomplete(
        taskId: task.id,
        plotId: task.plotId,
      );
      return true;
    } on Exception {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTask() async {
    if (isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      await repository.deleteTask(taskId: task.id, plotId: task.plotId);
      return true;
    } on Exception {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
