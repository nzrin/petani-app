import 'package:petani/project/models/project_form_data.dart';

class ProjectRecord {
  const ProjectRecord({
    required this.key,
    required this.projectName,
    required this.location,
    required this.cropTypes,
    required this.plots,
  });

  final String key;
  final String projectName;
  final String location;
  final List<ProjectCropType> cropTypes;
  final List<PlotRecord> plots;
}

class ProjectCropType {
  const ProjectCropType({required this.code, required this.name});

  final String code;
  final String name;
}

class PlotRecord {
  const PlotRecord({
    required this.id,
    required this.name,
    required this.cropCode,
    required this.cropName,
    required this.imagePath,
    required this.varieties,
    required this.raisedBedCount,
    required this.plantedAt,
  });

  final int id;
  final String name;
  final String cropCode;
  final String cropName;
  final String imagePath;
  final List<CropVariety> varieties;
  final int raisedBedCount;
  final DateTime? plantedAt;

  String get varietyLabel =>
      varieties.map((variety) => variety.label).join(', ');
}
