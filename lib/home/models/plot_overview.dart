import 'package:petani/shared/models/crop_harvest_estimate.dart';

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
    this.harvestEstimate,
    this.hasMixedVarieties = false,
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
  final CropHarvestEstimate? harvestEstimate;
  final bool hasMixedVarieties;

  String get harvestLabel {
    if (daysToHarvest == null) return 'anggaran tuaian belum tersedia';
    final milestone = harvestEstimate?.milestone.label ?? 'tuaian pertama';
    return daysToHarvest == 0
        ? 'anggaran $milestone telah tiba'
        : 'ke anggaran $milestone';
  }

  String get harvestExplanation {
    final estimate = harvestEstimate;
    if (estimate == null) return 'Anggaran tanaman belum tersedia.';
    return [
      if (totalPlants <= 0) 'Rekodkan bilangan pokok untuk melihat anggaran.',
      if (daysToHarvest == null && totalPlants > 0)
        'Rekodkan tarikh tanam untuk melihat anggaran.',
      estimate.plantingDateHelp,
      estimate.notes,
      if (hasMixedVarieties)
        'Plot campuran: tarikh terawal antara varieti yang dipilih untuk plot.',
      'Sumber: ${estimate.sourceName}',
    ].join('\n\n');
  }
}
