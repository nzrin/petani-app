import 'package:petani/project/models/crop_row_terminology.dart';

enum FarmTaskType {
  fungusControl('fungus_control', 'Kawalan Kulat'),
  insectControl('insect_control', 'Kawalan Serangga'),
  weedControl('weed_control', 'Kawalan Rumpai'),
  fertilizing('fertilizing', 'Membaja'),
  fruitHarvest('fruit_harvest', 'Menuai Hasil'),
  replanting('replanting', 'Menyulam'),
  seedHarvest('seed_harvest', 'Menuai Benih'),
  bedCleaning('bed_cleaning', 'Mencuci'),
  rubberTapping('rubber_tapping', 'Menoreh'),
  irrigation('irrigation', 'Pengairan'),
  pruning('pruning', 'Pemangkasan'),
  flowerInduction('flower_induction', 'Aruhan Pembungaan'),
  bunchBagging('bunch_bagging', 'Membungkus Tandan'),
  ploughing('ploughing', 'Membajak'),
  seedSowing('seed_sowing', 'Menabur Benih'),
  planting('planting', 'Menanam'),
  bedPreparation('bed_preparation', 'Menyediakan Batas'),
  supportInstallation('support_installation', 'Memasang Sokongan'),
  mulching('mulching', 'Memasang Sungkupan'),
  manualPollination('manual_pollination', 'Pendebungaan Manual'),
  fruitThinning('fruit_thinning', 'Penjarangan Buah'),
  vineLifting('vine_lifting', 'Mengangkat Sulur');

  const FarmTaskType(this.code, this._label);

  final String code;
  final String _label;

  String get label => labelForCrop('pineapple');

  String labelForCrop(String cropCode) {
    if (this == FarmTaskType.seedSowing) {
      if (cropCode == 'corn') return 'Menanam Benih';
      if (const {
        'watermelon',
        'rock_melon',
        'chilli',
        'cucumber',
        'eggplant',
      }.contains(cropCode)) {
        return 'Menyemai Benih';
      }
    }
    if (this == FarmTaskType.fruitHarvest) {
      if (cropCode == 'rice') return 'Menuai Padi';
      if (cropCode == 'torch_ginger') return 'Menuai Bunga';
    }
    if (this != FarmTaskType.bedCleaning) return _label;
    final terminology = CropRowTerminology.forCropCode(cropCode);
    return 'Mencuci ${terminology.title}';
  }

  String get imagePath => 'assets/images/tasks/$code.png';

  /// Convenient defaults for each crop; every type remains available through
  /// "Semua Tugasan", including nursery work and less common activities.
  static List<FarmTaskType> suggestedForCrop(String cropCode) {
    const supportedCrops = {
      'pineapple',
      'coconut',
      'banana',
      'oil_palm',
      'rubber_tree',
      'ginger',
      'rice',
      'torch_ginger',
      'corn',
      'cassava',
      'sweet_potato',
      'durian',
      'watermelon',
      'rock_melon',
      'strawberry',
      'chilli',
      'cucumber',
      'eggplant',
    };
    if (!supportedCrops.contains(cropCode)) return values;
    return List.unmodifiable(
      values.where(
        (type) => switch (type) {
          fruitHarvest => cropCode != 'rubber_tree',
          seedHarvest => cropCode == 'pineapple' || cropCode == 'ginger',
          rubberTapping => cropCode == 'rubber_tree',
          pruning => const {
            'coconut',
            'banana',
            'oil_palm',
            'rubber_tree',
            'torch_ginger',
            'durian',
            'watermelon',
            'rock_melon',
            'strawberry',
            'chilli',
            'cucumber',
            'eggplant',
          }.contains(cropCode),
          flowerInduction => cropCode == 'pineapple',
          bunchBagging => cropCode == 'banana',
          ploughing => const {
            'rice',
            'corn',
            'cassava',
            'sweet_potato',
            'watermelon',
          }.contains(cropCode),
          seedSowing => const {
            'rice',
            'corn',
            'watermelon',
            'rock_melon',
            'chilli',
            'cucumber',
            'eggplant',
          }.contains(cropCode),
          planting => true,
          bedPreparation =>
            CropRowTerminology.forCropCode(cropCode).title == 'Batas',
          supportInstallation => const {
            'cucumber',
            'rock_melon',
            'chilli',
            'eggplant',
          }.contains(cropCode),
          mulching => const {
            'pineapple',
            'ginger',
            'watermelon',
            'rock_melon',
            'strawberry',
            'chilli',
            'cucumber',
            'eggplant',
          }.contains(cropCode),
          manualPollination => cropCode == 'rock_melon',
          fruitThinning => cropCode == 'durian',
          vineLifting => cropCode == 'sweet_potato',
          _ => true,
        },
      ),
    );
  }

  bool get supportsControlMethod => switch (this) {
    FarmTaskType.fungusControl ||
    FarmTaskType.insectControl ||
    FarmTaskType.weedControl ||
    FarmTaskType.fertilizing => true,
    _ => false,
  };

  static FarmTaskType fromCode(String code) {
    return values.firstWhere(
      (type) => type.code == code,
      orElse: () => FarmTaskType.bedCleaning,
    );
  }
}

enum TaskControlMethod {
  organic('organic', 'Organik'),
  chemical('chemical', 'Kimia');

  const TaskControlMethod(this.code, this.label);

  final String code;
  final String label;

  static TaskControlMethod? fromCode(String? code) {
    if (code == null) return null;
    for (final method in values) {
      if (method.code == code) return method;
    }
    return null;
  }
}

class TaskFormData {
  const TaskFormData({
    required this.plotId,
    required this.type,
    required this.includesAllRaisedBeds,
    required this.raisedBedIds,
    required this.scheduledAt,
    required this.notes,
    this.cropCode = 'pineapple',
    this.controlMethod,
  });

  final int plotId;
  final String cropCode;
  final FarmTaskType type;
  final bool includesAllRaisedBeds;
  final Set<int> raisedBedIds;
  final DateTime scheduledAt;
  final String notes;
  final TaskControlMethod? controlMethod;
}
