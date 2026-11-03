class CropVariety {
  const CropVariety({required this.code, required this.name});

  final String code;
  final String name;

  String get label => code == name ? name : '$code - $name';

  @override
  bool operator ==(Object other) {
    return other is CropVariety && other.code == code && other.name == name;
  }

  @override
  int get hashCode => Object.hash(code, name);
}

class ProjectFormData {
  const ProjectFormData({
    required this.cropCode,
    required this.projectName,
    required this.location,
    required this.plotName,
    required this.varieties,
    required this.raisedBedCount,
    required this.plantedAt,
  });

  final String cropCode;
  final String projectName;
  final String location;
  final String plotName;
  final List<CropVariety> varieties;
  final int raisedBedCount;
  final DateTime plantedAt;
}
