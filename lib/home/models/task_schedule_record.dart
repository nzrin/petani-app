import 'package:petani/project/models/task_form_data.dart';

class TaskScheduleRecord {
  const TaskScheduleRecord({
    required this.id,
    required this.plotId,
    required this.type,
    required this.cropCode,
    required this.cropName,
    required this.projectName,
    required this.plotName,
    required this.location,
    required this.scheduledAt,
    required this.isCompleted,
  });

  final int id;
  final int plotId;
  final FarmTaskType type;
  final String cropCode;
  final String cropName;
  final String projectName;
  final String plotName;
  final String location;
  final DateTime scheduledAt;
  final bool isCompleted;

  String get title => type.labelForCrop(cropCode);

  String get contextLabel => '$projectName · $plotName';

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return <String>[
      title,
      cropName,
      projectName,
      plotName,
      location,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }
}
