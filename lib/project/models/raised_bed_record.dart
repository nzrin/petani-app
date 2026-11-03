import 'package:petani/project/models/project_form_data.dart';

class RaisedBedRecord {
  const RaisedBedRecord({
    required this.id,
    required this.plotId,
    required this.bedNumber,
    required this.seedlingCount,
    this.varieties = const [],
  });

  final int id;
  final int plotId;
  final int bedNumber;
  final int? seedlingCount;
  final List<CropVariety> varieties;

  bool get isConfigured => seedlingCount != null;

  String get varietyGridLabel {
    if (varieties.isEmpty) return '—';
    if (varieties.length == 1) return varieties.single.code;
    return '${varieties.first.code} +${varieties.length - 1}';
  }

  RaisedBedRecord withSeedlingCount(int? value) {
    return RaisedBedRecord(
      id: id,
      plotId: plotId,
      bedNumber: bedNumber,
      seedlingCount: value,
      varieties: varieties,
    );
  }

  RaisedBedRecord withDetails({
    required int? seedlingCount,
    required List<CropVariety> varieties,
  }) {
    return RaisedBedRecord(
      id: id,
      plotId: plotId,
      bedNumber: bedNumber,
      seedlingCount: seedlingCount,
      varieties: List.unmodifiable(varieties),
    );
  }
}
