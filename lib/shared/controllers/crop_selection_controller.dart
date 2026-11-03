import 'package:flutter/material.dart';
import 'package:petani/shared/models/crop_option.dart';

class CropSelectionController extends ChangeNotifier {
  CropSelectionController() : _selectedCrop = cropOptions.first;

  static const cropOptions = <CropOption>[
    CropOption(
      code: 'pineapple',
      name: 'Nanas',
      imagePath: 'assets/images/crops/pineapple.png',
      description: 'Urus plot dan jadual tanaman nanas.',
      isAvailable: true,
    ),
    CropOption(
      code: 'coconut',
      name: 'Kelapa',
      imagePath: 'assets/images/crops/coconut.png',
      description: 'Urus plot dan jadual tanaman kelapa.',
      isAvailable: true,
    ),
    CropOption(
      code: 'banana',
      name: 'Pisang',
      imagePath: 'assets/images/crops/banana.png',
      description: 'Urus plot dan jadual tanaman pisang.',
      isAvailable: true,
    ),
    CropOption(
      code: 'oil_palm',
      name: 'Sawit',
      imagePath: 'assets/images/crops/oil_palm.png',
      description: 'Urus plot dan jadual tanaman sawit.',
      isAvailable: true,
    ),
    CropOption(
      code: 'rubber_tree',
      name: 'Getah',
      imagePath: 'assets/images/crops/rubber_tree.png',
      description: 'Urus plot dan jadual tanaman getah.',
      isAvailable: true,
    ),
    CropOption(
      code: 'ginger',
      name: 'Halia',
      imagePath: 'assets/images/crops/ginger.png',
      description: 'Urus plot dan jadual tanaman halia.',
      isAvailable: true,
    ),
    CropOption(
      code: 'rice',
      name: 'Padi',
      imagePath: 'assets/images/crops/rice.png',
      description: 'Urus petak sawah dan jadual tanaman padi.',
      isAvailable: true,
    ),
    CropOption(
      code: 'torch_ginger',
      name: 'Bunga Kantan',
      imagePath: 'assets/images/crops/torch_ginger.png',
      description: 'Urus plot dan jadual tanaman bunga kantan.',
      isAvailable: true,
    ),
    CropOption(
      code: 'corn',
      name: 'Jagung',
      imagePath: 'assets/images/crops/corn.png',
      description: 'Urus plot dan jadual tanaman jagung.',
      isAvailable: true,
    ),
    CropOption(
      code: 'cassava',
      name: 'Ubi Kayu',
      imagePath: 'assets/images/crops/cassava.png',
      description: 'Urus plot dan jadual tanaman ubi kayu.',
      isAvailable: true,
    ),
    CropOption(
      code: 'durian',
      name: 'Durian',
      imagePath: 'assets/images/crops/durian.png',
      description: 'Urus plot dan jadual tanaman durian.',
      isAvailable: true,
    ),
    CropOption(
      code: 'sweet_potato',
      name: 'Ubi Keledek',
      imagePath: 'assets/images/crops/sweet_potato.png',
      description: 'Urus plot dan jadual tanaman ubi keledek.',
      isAvailable: true,
    ),
    CropOption(
      code: 'watermelon',
      name: 'Tembikai',
      imagePath: 'assets/images/crops/watermelon.png',
      description: 'Urus plot dan jadual tanaman tembikai.',
      isAvailable: true,
    ),
    CropOption(
      code: 'rock_melon',
      name: 'Rock Melon',
      imagePath: 'assets/images/crops/rock_melon.png',
      description: 'Urus plot dan jadual tanaman rock melon.',
      isAvailable: true,
    ),
    CropOption(
      code: 'strawberry',
      name: 'Strawberi',
      imagePath: 'assets/images/crops/strawberry.png',
      description: 'Urus plot dan jadual tanaman strawberi.',
      isAvailable: true,
    ),
    CropOption(
      code: 'chilli',
      name: 'Cili',
      imagePath: 'assets/images/crops/chilli.png',
      description: 'Urus plot dan jadual tanaman cili.',
      isAvailable: true,
    ),
    CropOption(
      code: 'cucumber',
      name: 'Timun',
      imagePath: 'assets/images/crops/cucumber.png',
      description: 'Urus plot dan jadual tanaman timun.',
      isAvailable: true,
    ),
    CropOption(
      code: 'eggplant',
      name: 'Terung',
      imagePath: 'assets/images/crops/eggplant.png',
      description: 'Urus plot dan jadual tanaman terung.',
      isAvailable: true,
    ),
    CropOption(
      code: 'lime',
      name: 'Limau Nipis',
      imagePath: 'assets/images/crops/lime.png',
      description: 'Urus plot dan jadual tanaman limau nipis.',
      isAvailable: false,
    ),
    CropOption(
      code: 'pandan',
      name: 'Pandan',
      imagePath: 'assets/images/crops/pandan.png',
      description: 'Urus plot dan jadual tanaman pandan.',
      isAvailable: false,
    ),
    CropOption(
      code: 'lemongrass',
      name: 'Serai',
      imagePath: 'assets/images/crops/lemongrass.png',
      description: 'Urus plot dan jadual tanaman serai.',
      isAvailable: false,
    ),
    CropOption(
      code: 'tomato',
      name: 'Tomato',
      imagePath: 'assets/images/crops/tomato.png',
      description: 'Urus plot dan jadual tanaman tomato.',
      isAvailable: false,
    ),
    CropOption(
      code: 'turmeric',
      name: 'Kunyit',
      imagePath: 'assets/images/crops/turmeric.png',
      description: 'Urus plot dan jadual tanaman kunyit.',
      isAvailable: false,
    ),
    CropOption(
      code: 'calamansi',
      name: 'Limau Kasturi',
      imagePath: 'assets/images/crops/calamansi.png',
      description: 'Urus plot dan jadual tanaman limau kasturi.',
      isAvailable: false,
    ),
    CropOption(
      code: 'kesum',
      name: 'Kesum',
      imagePath: 'assets/images/crops/kesum.png',
      description: 'Urus plot dan jadual tanaman kesum.',
      isAvailable: false,
    ),
  ];

  String _cropQuery = '';
  bool _showGrid = true;
  CropOption _selectedCrop;

  CropOption get selectedCrop => _selectedCrop;
  bool get canContinue =>
      _selectedCrop.isAvailable && filteredCropOptions.contains(_selectedCrop);
  bool get showGrid => _showGrid;

  void setShowGrid(bool value) {
    if (_showGrid == value) return;
    _showGrid = value;
    notifyListeners();
  }

  List<CropOption> get filteredCropOptions {
    final crops = cropOptions
        .where((crop) => crop.name.toLowerCase().contains(_cropQuery))
        .toList(growable: false);
    crops.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return crops;
  }

  void selectCrop(CropOption crop) {
    if (!crop.isAvailable || _selectedCrop == crop) return;
    _selectedCrop = crop;
    notifyListeners();
  }

  void searchCrops(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (_cropQuery == normalizedQuery) return;
    _cropQuery = normalizedQuery;

    final visibleCrops = filteredCropOptions
        .where((crop) => crop.isAvailable)
        .toList(growable: false);
    if (visibleCrops.isNotEmpty && !visibleCrops.contains(_selectedCrop)) {
      _selectedCrop = visibleCrops.first;
    }
    notifyListeners();
  }
}
