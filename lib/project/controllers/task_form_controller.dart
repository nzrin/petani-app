import 'package:flutter/foundation.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/models/task_form_data.dart';

class TaskFormController extends ChangeNotifier {
  static const defaultTaskHour = 7;
  static const defaultTaskMinute = 30;

  TaskFormController({
    required this.plotId,
    required this.cropCode,
    required this.raisedBeds,
    DateTime? initialDate,
    PlotTaskRecord? initialTask,
  }) : selectedType = initialTask?.type,
       selectedControlMethod = initialTask?.controlMethod,
       includesAllRaisedBeds = initialTask?.includesAllRaisedBeds ?? true,
       selectedRaisedBedIds = _selectedIds(raisedBeds, initialTask),
       scheduledAt = _initialScheduledAt(
         initialTask: initialTask,
         initialDate: initialDate,
       ),
       notes = initialTask?.notes ?? '' {
    _showAllTaskTypes =
        initialTask != null &&
        !FarmTaskType.suggestedForCrop(cropCode).contains(initialTask.type);
  }

  final int plotId;
  final String cropCode;
  final List<RaisedBedRecord> raisedBeds;

  FarmTaskType? selectedType;
  TaskControlMethod? selectedControlMethod;
  bool includesAllRaisedBeds;
  Set<int> selectedRaisedBedIds;
  DateTime scheduledAt;
  String notes;
  bool _showAllTaskTypes = false;

  bool get showAllTaskTypes => _showAllTaskTypes;

  List<FarmTaskType> get visibleTaskTypes {
    if (_showAllTaskTypes) return FarmTaskType.values;
    final suggested = FarmTaskType.suggestedForCrop(cropCode);
    // Keep an existing selection visible when returning to the crop defaults.
    return List.unmodifiable(
      FarmTaskType.values.where(
        (type) => suggested.contains(type) || type == selectedType,
      ),
    );
  }

  void toggleTaskTypes() {
    setShowAllTaskTypes(!_showAllTaskTypes);
  }

  void setShowAllTaskTypes(bool value) {
    if (_showAllTaskTypes == value) return;
    _showAllTaskTypes = value;
    notifyListeners();
  }

  bool get canSubmit {
    return selectedType != null &&
        (includesAllRaisedBeds || selectedRaisedBedIds.isNotEmpty);
  }

  void selectType(FarmTaskType type) {
    if (selectedType == type) return;
    selectedType = type;
    selectedControlMethod = null;
    notifyListeners();
  }

  void setIncludesAllRaisedBeds(bool value) {
    if (includesAllRaisedBeds == value) return;
    includesAllRaisedBeds = value;
    notifyListeners();
  }

  void setSelectedRaisedBeds(Set<int> value) {
    selectedRaisedBedIds = Set.unmodifiable(value);
    notifyListeners();
  }

  void setScheduledAt(DateTime value) {
    scheduledAt = DateTime(
      value.year,
      value.month,
      value.day,
      scheduledAt.hour,
      scheduledAt.minute,
    );
    notifyListeners();
  }

  void setScheduledTime({required int hour, required int minute}) {
    scheduledAt = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      hour,
      minute,
    );
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
  }

  TaskFormData buildResult() {
    final type = selectedType;
    if (type == null || !canSubmit) {
      throw StateError('Task form is incomplete.');
    }
    return TaskFormData(
      plotId: plotId,
      cropCode: cropCode,
      type: type,
      includesAllRaisedBeds: includesAllRaisedBeds,
      raisedBedIds: includesAllRaisedBeds
          ? const <int>{}
          : selectedRaisedBedIds,
      scheduledAt: scheduledAt,
      notes: notes.trim(),
      controlMethod: type.supportsControlMethod ? selectedControlMethod : null,
    );
  }
}

DateTime _initialScheduledAt({
  required PlotTaskRecord? initialTask,
  required DateTime? initialDate,
}) {
  final existing = initialTask?.scheduledAt;
  if (existing != null) {
    return DateTime(
      existing.year,
      existing.month,
      existing.day,
      existing.hour,
      existing.minute,
    );
  }
  final date = initialDate ?? DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
    TaskFormController.defaultTaskHour,
    TaskFormController.defaultTaskMinute,
  );
}

Set<int> _selectedIds(
  List<RaisedBedRecord> raisedBeds,
  PlotTaskRecord? initialTask,
) {
  if (initialTask == null || initialTask.includesAllRaisedBeds) return {};
  return raisedBeds
      .where(
        (raisedBed) =>
            initialTask.raisedBedNumbers.contains(raisedBed.bedNumber),
      )
      .map((raisedBed) => raisedBed.id)
      .toSet();
}
