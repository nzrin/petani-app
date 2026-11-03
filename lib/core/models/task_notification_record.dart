import 'package:petani/project/models/task_form_data.dart';

class TaskNotificationRecord {
  const TaskNotificationRecord({
    required this.id,
    required this.taskId,
    required this.plotId,
    required this.type,
    required this.cropCode,
    required this.title,
    required this.message,
    required this.receivedAt,
    required this.taskScheduledAt,
    required this.projectName,
    required this.plotName,
    required this.isTaskAvailable,
    required this.isRead,
  });

  final int id;
  final int taskId;
  final int plotId;
  final FarmTaskType type;
  final String cropCode;
  final String title;
  final String message;
  final DateTime receivedAt;
  final DateTime taskScheduledAt;
  final String projectName;
  final String plotName;
  final bool isTaskAvailable;
  final bool isRead;

  TaskNotificationRecord copyWith({bool? isRead}) {
    return TaskNotificationRecord(
      id: id,
      taskId: taskId,
      plotId: plotId,
      type: type,
      cropCode: cropCode,
      title: title,
      message: message,
      receivedAt: receivedAt,
      taskScheduledAt: taskScheduledAt,
      projectName: projectName,
      plotName: plotName,
      isTaskAvailable: isTaskAvailable,
      isRead: isRead ?? this.isRead,
    );
  }
}
