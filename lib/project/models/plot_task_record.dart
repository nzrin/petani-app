import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/models/task_control_product.dart';

class PlotTaskRecord {
  const PlotTaskRecord({
    required this.id,
    required this.plotId,
    required this.type,
    required this.scheduledAt,
    required this.notes,
    required this.raisedBedNumbers,
    required this.isCompleted,
    required this.completedAt,
    this.cropCode = 'pineapple',
    this.controlMethod,
    this.controlProducts = const [],
  });

  final int id;
  final int plotId;
  final FarmTaskType type;
  final DateTime scheduledAt;
  final String notes;
  final List<int> raisedBedNumbers;
  final bool isCompleted;
  final DateTime? completedAt;
  final String cropCode;
  final TaskControlMethod? controlMethod;
  final List<TaskControlProduct> controlProducts;

  bool get includesAllRaisedBeds => raisedBedNumbers.isEmpty;

  String raisedBedSummary(int totalRaisedBeds, {String? forCropCode}) {
    final terminology = CropRowTerminology.forCropCode(forCropCode ?? cropCode);
    if (includesAllRaisedBeds) {
      return 'Semua ${terminology.count(totalRaisedBeds)}';
    }
    if (raisedBedNumbers.length == 1) {
      return '${terminology.title} ${raisedBedNumbers.single}';
    }
    return '${terminology.count(raisedBedNumbers.length)} dipilih';
  }

  PlotTaskRecord copyWith({
    FarmTaskType? type,
    DateTime? scheduledAt,
    String? notes,
    List<int>? raisedBedNumbers,
    bool? isCompleted,
    DateTime? completedAt,
    Object? controlMethod = _unsetControlMethod,
    List<TaskControlProduct>? controlProducts,
  }) {
    return PlotTaskRecord(
      id: id,
      plotId: plotId,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notes: notes ?? this.notes,
      raisedBedNumbers: raisedBedNumbers ?? this.raisedBedNumbers,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      cropCode: cropCode,
      controlMethod: identical(controlMethod, _unsetControlMethod)
          ? this.controlMethod
          : controlMethod as TaskControlMethod?,
      controlProducts: controlProducts ?? this.controlProducts,
    );
  }
}

const Object _unsetControlMethod = Object();
