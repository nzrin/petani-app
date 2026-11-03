import 'package:flutter/material.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/models/crop_variety_catalog.dart';

class ProjectFormController extends ChangeNotifier {
  ProjectFormController({
    String cropCode = 'pineapple',
    this.suggestions = const ProjectFormSuggestions(),
    ExistingProjectSuggestion? fixedProject,
    ProjectFormData? initialData,
    this.requireExistingProject = false,
  }) : cropCode = initialData?.cropCode ?? cropCode,
       selectedVarieties = {},
       plantedAt = DateUtils.dateOnly(initialData?.plantedAt ?? DateTime.now()),
       isPlotOnlyFlow = fixedProject != null,
       isEditing = initialData != null,
       _initialPlotName = initialData?.plotName {
    if (fixedProject != null) {
      selectedExistingProject = fixedProject;
      projectNameController.text = fixedProject.name;
      locationController.text = fixedProject.location;
      currentStep = 2;
    }

    if (initialData != null) {
      plotNameController.text = initialData.plotName;
      selectedRaisedBedCount = initialData.raisedBedCount.clamp(1, 50);
      if (initialData.raisedBedCount > 50) {
        customRaisedBedController.text = '${initialData.raisedBedCount}';
      }
      final initialCodes = initialData.varieties
          .map((variety) => variety.code)
          .toSet();
      selectedVarieties.addAll(
        availableVarieties.where(
          (variety) => initialCodes.contains(variety.code),
        ),
      );
      if (this.cropCode == 'torch_ginger' &&
          initialCodes.contains(CropVarietyCatalog.legacyTorchGinger.code)) {
        selectedVarieties.add(CropVarietyCatalog.legacyTorchGinger);
      }
    }
  }

  String cropCode;
  final ProjectFormSuggestions suggestions;
  final bool isPlotOnlyFlow;
  final bool isEditing;
  final bool requireExistingProject;
  final String? _initialPlotName;

  final projectNameController = TextEditingController();
  final locationController = TextEditingController();
  final plotNameController = TextEditingController();
  final customRaisedBedController = TextEditingController();

  static const pineappleVarieties = <CropVariety>[
    CropVariety(code: 'AC1', name: 'Moris'),
    CropVariety(code: 'AC2', name: 'Sarawak'),
    CropVariety(code: 'AC3', name: 'Gandol'),
    CropVariety(code: 'AC4', name: 'Maspine'),
    CropVariety(code: 'AC5', name: 'Josapine'),
    CropVariety(code: 'AC6', name: 'Yankee'),
    CropVariety(code: 'AC7', name: 'Moris Gajah'),
    CropVariety(code: 'AC8', name: 'N36'),
    CropVariety(code: 'AC9', name: 'MD2'),
    CropVariety(code: 'AC10', name: 'View of Sunset'),
    CropVariety(code: 'AC11', name: 'Madu Kaca'),
    CropVariety(code: 'AC12', name: 'Keningau Diamond'),
    CropVariety(code: 'AC13', name: 'Cobek'),
    CropVariety(code: 'AC14', name: 'Crystal Honey'),
    CropVariety(code: 'AC15', name: 'Jambul Emas A18'),
    CropVariety(code: 'AC16', name: 'SG1'),
  ];

  static const coconutVarieties = <CropVariety>[
    CropVariety(code: 'CN1', name: 'Malayan Tall'),
    CropVariety(code: 'CN2', name: 'West African Tall Green'),
    CropVariety(code: 'CN3', name: 'Mawa'),
    CropVariety(code: 'CN4', name: 'Malayan Red Dwarf'),
    CropVariety(code: 'CN5', name: 'Malayan Yellow Dwarf'),
    CropVariety(code: 'CN6', name: 'Aromatic Dwarf / Pandan'),
    CropVariety(code: 'CN7', name: 'Tagnanan Green'),
    CropVariety(code: 'CN8', name: 'Tagnanan Orange'),
    CropVariety(code: 'CN9', name: 'Tagnanan Gold'),
    CropVariety(code: 'CN10', name: 'Rennal Tall Green'),
    CropVariety(code: 'CN11', name: 'Rennal Tall Orange'),
    CropVariety(code: 'CN12', name: 'Rennal Tall Gold'),
    CropVariety(code: 'CN13', name: 'Matag Green'),
    CropVariety(code: 'CN14', name: 'Matag Orange'),
    CropVariety(code: 'CN15', name: 'Matag Gold'),
    CropVariety(code: 'CN16', name: 'SGG (Sungai Gulang-Gulang)'),
  ];

  static const supportedCrops = <String, String>{
    'pineapple': 'Nanas',
    'coconut': 'Kelapa',
    'banana': 'Pisang',
    'oil_palm': 'Sawit',
    'rubber_tree': 'Getah',
    'ginger': 'Halia',
    'rice': 'Padi',
    'torch_ginger': 'Bunga Kantan',
    'corn': 'Jagung',
    'cassava': 'Ubi Kayu',
    'sweet_potato': 'Ubi Keledek',
    'durian': 'Durian',
    'watermelon': 'Tembikai',
    'rock_melon': 'Rock Melon',
    'strawberry': 'Strawberi',
    'chilli': 'Cili',
    'cucumber': 'Timun',
    'eggplant': 'Terung',
  };

  int currentStep = 0;
  int selectedRaisedBedCount = 1;
  final Set<CropVariety> selectedVarieties;
  late DateTime plantedAt;
  ExistingProjectSuggestion? selectedExistingProject;

  bool get isLastStep => currentStep == 3;
  bool get isAddingPlotToExistingProject =>
      isPlotOnlyFlow || requireExistingProject;
  bool get isFirstVisibleStep =>
      isPlotOnlyFlow ? currentStep == 2 : currentStep == 0;
  bool get hasSelectedExistingProject => selectedExistingProject != null;
  int get visibleStepCount {
    if (isPlotOnlyFlow) return 2;
    if (requireExistingProject) return 3;
    return hasSelectedExistingProject ? 3 : 4;
  }

  int get visibleStepIndex {
    if (isPlotOnlyFlow) return currentStep == 2 ? 0 : 1;
    if (requireExistingProject) {
      return switch (currentStep) {
        0 => 0,
        2 => 1,
        3 => 2,
        _ => 0,
      };
    }
    if (!hasSelectedExistingProject) return currentStep;
    return switch (currentStep) {
      0 => 0,
      2 => 1,
      3 => 2,
      _ => 0,
    };
  }

  List<CropVariety> get availableVarieties => switch (cropCode) {
    'pineapple' => pineappleVarieties,
    'coconut' => coconutVarieties,
    'banana' => CropVarietyCatalog.banana,
    'oil_palm' => CropVarietyCatalog.oilPalm,
    'rubber_tree' => CropVarietyCatalog.rubber,
    'ginger' => CropVarietyCatalog.ginger,
    'rice' => CropVarietyCatalog.rice,
    'corn' => CropVarietyCatalog.corn,
    'cassava' => CropVarietyCatalog.cassava,
    'sweet_potato' => CropVarietyCatalog.sweetPotato,
    'durian' => CropVarietyCatalog.durian,
    'watermelon' => CropVarietyCatalog.watermelon,
    'rock_melon' => CropVarietyCatalog.rockMelon,
    'strawberry' => CropVarietyCatalog.strawberry,
    'chilli' => CropVarietyCatalog.chilli,
    'cucumber' => CropVarietyCatalog.cucumber,
    'eggplant' => CropVarietyCatalog.eggplant,
    'torch_ginger' => [
      ...CropVarietyCatalog.torchGinger,
      if (selectedVarieties.contains(CropVarietyCatalog.legacyTorchGinger))
        CropVarietyCatalog.legacyTorchGinger,
    ],
    _ => const [],
  };

  String get varietyFieldTitle => CropVarietyCatalog.fieldTitle(cropCode);

  bool get canContinue {
    return switch (currentStep) {
      0 =>
        requireExistingProject
            ? selectedExistingProject != null
            : projectNameController.text.trim().isNotEmpty,
      1 => locationController.text.trim().isNotEmpty,
      2 => plotNameController.text.trim().isNotEmpty && !plotNameAlreadyExists,
      3 => selectedVarieties.isNotEmpty && _customRaisedBedCountIsValid,
      _ => false,
    };
  }

  bool get plotNameAlreadyExists {
    final project = selectedExistingProject;
    final plotName = _normalizeName(plotNameController.text);
    if (project == null || plotName.isEmpty) return false;
    return project.plotNames.any((existingName) {
      final normalizedExistingName = _normalizeName(existingName);
      final normalizedInitialName = _normalizeName(_initialPlotName ?? '');
      if (isEditing && normalizedExistingName == normalizedInitialName) {
        return false;
      }
      return normalizedExistingName == plotName;
    });
  }

  bool get _customRaisedBedCountIsValid {
    final value = customRaisedBedController.text.trim();
    if (value.isEmpty) return true;
    final parsedValue = int.tryParse(value);
    return parsedValue != null && parsedValue > 0;
  }

  int get raisedBedCount {
    final customValue = int.tryParse(customRaisedBedController.text.trim());
    return customValue != null && customValue > 0
        ? customValue
        : selectedRaisedBedCount;
  }

  void refresh() => notifyListeners();

  void updateProjectName(String value) {
    final normalizedValue = _normalizeProjectName(value);
    ExistingProjectSuggestion? matchingProject;
    for (final project in suggestions.existingProjects) {
      if (_normalizeProjectName(project.name) == normalizedValue) {
        matchingProject = project;
        break;
      }
    }

    if (matchingProject != null) {
      selectedExistingProject = matchingProject;
      _setFieldValue(
        locationController,
        matchingProject.location,
        notify: false,
      );
    } else if (selectedExistingProject != null) {
      selectedExistingProject = null;
      locationController.clear();
    }
    notifyListeners();
  }

  String _normalizeProjectName(String value) {
    return _normalizeName(value);
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void selectExistingProject(ExistingProjectSuggestion project) {
    selectedExistingProject = project;
    _setFieldValue(projectNameController, project.name, notify: false);
    _setFieldValue(locationController, project.location, notify: false);
    notifyListeners();
  }

  void selectExistingProjectByName(String name) {
    final project = suggestions.existingProjects.firstWhere(
      (suggestion) => suggestion.name == name,
    );
    selectExistingProject(project);
  }

  void selectLocation(String value) {
    _setFieldValue(locationController, value);
  }

  void _setFieldValue(
    TextEditingController controller,
    String value, {
    bool notify = true,
  }) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    if (notify) notifyListeners();
  }

  void nextStep() {
    if (!canContinue || isLastStep) return;
    currentStep = currentStep == 0 && hasSelectedExistingProject
        ? 2
        : currentStep + 1;
    notifyListeners();
  }

  void previousStep() {
    if (isFirstVisibleStep) return;
    if (isPlotOnlyFlow && currentStep == 3) {
      currentStep = 2;
      notifyListeners();
      return;
    }
    if (currentStep == 0) return;
    currentStep = currentStep == 2 && hasSelectedExistingProject
        ? 0
        : currentStep - 1;
    notifyListeners();
  }

  void toggleVariety(CropVariety variety) {
    if (cropCode == 'torch_ginger' &&
        CropVarietyCatalog.torchGinger.contains(variety)) {
      selectedVarieties.remove(CropVarietyCatalog.legacyTorchGinger);
    }
    if (!selectedVarieties.remove(variety)) {
      selectedVarieties.add(variety);
    }
    notifyListeners();
  }

  void selectCrop(String value) {
    if (cropCode == value || !supportedCrops.containsKey(value)) return;
    cropCode = value;
    selectedVarieties.clear();
    notifyListeners();
  }

  void selectRaisedBedCount(int count) {
    final hasCustomValue = customRaisedBedController.text.isNotEmpty;
    if (selectedRaisedBedCount == count && !hasCustomValue) return;
    selectedRaisedBedCount = count;
    customRaisedBedController.clear();
    notifyListeners();
  }

  void setPlantedAt(DateTime date) {
    plantedAt = DateUtils.dateOnly(date);
    notifyListeners();
  }

  ProjectFormData buildResult() {
    final existingProject = selectedExistingProject;
    return ProjectFormData(
      cropCode: cropCode,
      projectName: existingProject?.name ?? projectNameController.text.trim(),
      location: existingProject?.location ?? locationController.text.trim(),
      plotName: plotNameController.text.trim(),
      varieties: availableVarieties
          .where(selectedVarieties.contains)
          .toList(growable: false),
      raisedBedCount: raisedBedCount,
      plantedAt: plantedAt,
    );
  }

  @override
  void dispose() {
    projectNameController.dispose();
    locationController.dispose();
    plotNameController.dispose();
    customRaisedBedController.dispose();
    super.dispose();
  }
}
