import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/task_detail_view.dart';

Future<void> openUpcomingTaskDetail({
  required BuildContext context,
  required UpcomingTaskRecord task,
  TaskRepository? taskRepository,
  RaisedBedRepository? raisedBedRepository,
  Future<void> Function()? onChanged,
}) async {
  return openTaskDetailByReference(
    context: context,
    taskId: task.id,
    plotId: task.plotId,
    projectName: task.projectName,
    plotName: task.plotName,
    taskRepository: taskRepository,
    raisedBedRepository: raisedBedRepository,
    onChanged: onChanged,
  );
}

Future<void> openTaskDetailByReference({
  required BuildContext context,
  required int taskId,
  required int plotId,
  required String projectName,
  required String plotName,
  TaskRepository? taskRepository,
  RaisedBedRepository? raisedBedRepository,
  Future<void> Function()? onChanged,
}) async {
  final resolvedTaskRepository =
      taskRepository ?? createDefaultTaskRepository();
  final resolvedRaisedBedRepository =
      raisedBedRepository ?? SqliteRaisedBedRepository(AppDatabase.instance);

  try {
    final results = await Future.wait<Object>([
      resolvedTaskRepository.getTasks(plotId),
      resolvedRaisedBedRepository.getRaisedBeds(plotId),
    ]);
    final tasks = results[0] as List<PlotTaskRecord>;
    final raisedBeds = results[1] as List<RaisedBedRecord>;
    PlotTaskRecord? selectedTask;
    for (final candidate in tasks) {
      if (candidate.id == taskId) {
        selectedTask = candidate;
        break;
      }
    }
    if (selectedTask == null) {
      throw StateError('Task $taskId is no longer available.');
    }
    if (!context.mounted) return;

    void refreshTasks() {
      final callback = onChanged;
      if (callback != null) unawaited(callback());
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailView(
          task: selectedTask!,
          projectName: projectName,
          plotName: plotName,
          totalRaisedBeds: raisedBeds.length,
          raisedBeds: raisedBeds,
          repository: resolvedTaskRepository,
          onTaskChanged: (_) => refreshTasks(),
          onTaskDeleted: (_) => refreshTasks(),
        ),
      ),
    );
    if (context.mounted && onChanged != null) await onChanged();
  } catch (_) {
    if (!context.mounted) return;
    AppToast.show(
      context,
      'Butiran tugasan tidak dapat dibuka. Cuba lagi.',
      isError: true,
    );
  }
}
