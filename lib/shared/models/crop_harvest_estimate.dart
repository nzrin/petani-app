import 'dart:convert';

import 'package:flutter/services.dart';

enum HarvestMilestone {
  firstHarvest('first_harvest', 'tuaian pertama'),
  firstYield('first_yield', 'hasil pertama'),
  firstTapping('first_tapping', 'mula menoreh'),
  firstFlower('first_flower', 'bunga pertama');

  const HarvestMilestone(this.code, this.label);
  final String code;
  final String label;
}

/// Source-backed planning estimates, independent of crop-specific UI branches.
class CropHarvestEstimate {
  CropHarvestEstimate.fromJson(Map<String, dynamic> json)
    : cropCode = json['crop_code'] as String,
      estimateDays = json['estimate_days'] as int,
      minimumDays = json['minimum_days'] as int,
      maximumDays = json['maximum_days'] as int,
      varietyEstimateDays = Map.unmodifiable(
        (json['variety_estimate_days'] as Map<String, dynamic>).map(
          (code, days) => MapEntry(code, days as int),
        ),
      ),
      milestone = HarvestMilestone.values.firstWhere(
        (value) => value.code == json['milestone'],
      ),
      plantingDateHelp = json['planting_date_help'] as String,
      notes = json['notes'] as String,
      basis = json['basis'] as String,
      sourceName = json['source_name'] as String,
      sourceUrl = json['source_url'] as String {
    if (cropCode.trim().isEmpty ||
        minimumDays <= 0 ||
        maximumDays < minimumDays ||
        [
          estimateDays,
          ...varietyEstimateDays.values,
        ].any((days) => days < minimumDays || days > maximumDays) ||
        varietyEstimateDays.keys.any((code) => code.trim().isEmpty) ||
        [
          plantingDateHelp,
          notes,
          basis,
          sourceName,
        ].any((value) => value.trim().isEmpty) ||
        Uri.tryParse(sourceUrl)?.scheme != 'https' ||
        Uri.tryParse(sourceUrl)?.host.isEmpty != false) {
      throw FormatException('Invalid harvest estimate: $cropCode');
    }
  }

  final String cropCode;
  final int estimateDays;
  final int minimumDays;
  final int maximumDays;
  final Map<String, int> varietyEstimateDays;
  final HarvestMilestone milestone;
  final String plantingDateHelp;
  final String notes;
  final String basis;
  final String sourceName;
  final String sourceUrl;

  int daysFor(String? varietyCode) =>
      varietyEstimateDays[varietyCode?.trim()] ?? estimateDays;

  /// For mixed-variety plots, Home reports the earliest expected first yield.
  /// This is not a promise that every plant in the plot is ready together.
  int daysForVarieties(Iterable<String> varietyCodes) {
    final days = varietyCodes.map(daysFor).toList();
    return days.isEmpty ? estimateDays : days.reduce((a, b) => a < b ? a : b);
  }

  DateTime? harvestDate({
    required DateTime? plantedAt,
    required int totalPlants,
    Iterable<String> varietyCodes = const [],
  }) {
    if (plantedAt == null || totalPlants <= 0) return null;
    final local = plantedAt.toLocal();
    // Calendar arithmetic avoids 23/25-hour days changing the countdown.
    return DateTime(
      local.year,
      local.month,
      local.day + daysForVarieties(varietyCodes),
    );
  }

  static int? remainingDays(DateTime? harvestAt, DateTime now) {
    if (harvestAt == null) return null;
    DateTime calendarDay(DateTime value) {
      final local = value.toLocal();
      return DateTime.utc(local.year, local.month, local.day);
    }

    final days = calendarDay(harvestAt).difference(calendarDay(now)).inDays;
    return days < 0 ? 0 : days;
  }
}

class CropHarvestCatalog {
  CropHarvestCatalog.fromJson(String source) {
    final document = jsonDecode(source) as Map<String, dynamic>;
    if (document['version'] != 2) {
      throw const FormatException('Unsupported harvest catalog version');
    }
    final estimates = <String, CropHarvestEstimate>{};
    for (final crop in document['crops'] as List<dynamic>) {
      final estimate = CropHarvestEstimate.fromJson(
        crop as Map<String, dynamic>,
      );
      if (estimates.containsKey(estimate.cropCode)) {
        throw FormatException('Duplicate harvest crop: ${estimate.cropCode}');
      }
      estimates[estimate.cropCode] = estimate;
    }
    _estimates = Map.unmodifiable(estimates);
  }

  static const assetPath = 'assets/data/crop_harvest_estimates.json';
  static Future<CropHarvestCatalog>? _bundled;
  late final Map<String, CropHarvestEstimate> _estimates;

  /// Shared once per app session, including all future catalog entries.
  static Future<CropHarvestCatalog> load() => _bundled ??= rootBundle
      .loadString(assetPath)
      .then(CropHarvestCatalog.fromJson);

  CropHarvestEstimate? operator [](String cropCode) => _estimates[cropCode];

  /// Used by the catalog coverage test whenever a crop is enabled.
  void requireCoverage(Iterable<String> availableCropCodes) {
    final missing = availableCropCodes.toSet().difference(
      _estimates.keys.toSet(),
    );
    if (missing.isNotEmpty) {
      throw StateError(
        'Add sourced harvest estimates for: ${missing.join(', ')}',
      );
    }
  }
}
