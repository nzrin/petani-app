class PlotOverview {
  const PlotOverview({
    required this.plotId,
    required this.projectName,
    required this.plotName,
    required this.cropCode,
    required this.cropName,
    required this.imagePath,
    required this.totalPlants,
    required this.daysToHarvest,
    required this.estimatedHarvestAt,
  });

  final int plotId;
  final String projectName;
  final String plotName;
  final String cropCode;
  final String cropName;
  final String imagePath;
  final int totalPlants;
  final int? daysToHarvest;
  final DateTime? estimatedHarvestAt;
}
