import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/project/controllers/project_form_controller.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/crop_variety_catalog.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy kantan stays unknown until a colour is selected', () {
    final initial = ProjectFormData(
      cropCode: 'torch_ginger',
      projectName: 'Kantan',
      location: 'Johor',
      plotName: 'Plot A',
      varieties: const [CropVarietyCatalog.legacyTorchGinger],
      raisedBedCount: 2,
      plantedAt: DateTime(2026, 11, 3),
    );
    final controller = ProjectFormController(initialData: initial);
    addTearDown(controller.dispose);
    expect(controller.buildResult().varieties, initial.varieties);
    expect(
      controller.availableVarieties,
      contains(CropVarietyCatalog.legacyTorchGinger),
    );
    controller.toggleVariety(CropVarietyCatalog.torchGinger.first);
    expect(controller.buildResult().varieties.single.name, 'Merah Jambu');
    expect(
      controller.availableVarieties,
      isNot(contains(CropVarietyCatalog.legacyTorchGinger)),
    );
    expect(controller.varietyFieldTitle, 'Varieti (Warna)');
  });

  test('rice uses petak and crop-specific harvest names', () {
    final terms = CropRowTerminology.forCropCode('rice');
    expect(terms.title, 'Petak');
    expect(terms.count(3), '3 petak');
    expect(terms.abbreviation, 'P');
    expect(FarmTaskType.fruitHarvest.labelForCrop('rice'), 'Menuai Padi');
    expect(
      FarmTaskType.fruitHarvest.labelForCrop('torch_ginger'),
      'Menuai Bunga',
    );
    expect(CropRowTerminology.forCropCode('torch_ginger').title, 'Baris');
  });

  test(
    'new crops use their sourced varieties and clear previous selection',
    () async {
      final sources =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/crop_variety_sources.json',
                ),
              )
              as Map<String, dynamic>;
      final controller = ProjectFormController();
      addTearDown(controller.dispose);
      controller.plotNameController.text = 'Plot A';
      controller.currentStep = 3;

      for (final entry in sources['crops'] as List<dynamic>) {
        final code = entry['crop_code'] as String;
        controller.selectCrop(code);
        expect(controller.selectedVarieties, isEmpty);
        expect(controller.canContinue, isFalse);
        expect(
          CropSelectionController.cropOptions
              .singleWhere((crop) => crop.code == code)
              .isAvailable,
          isTrue,
        );
        expect({
          for (final variety in controller.availableVarieties)
            variety.code: variety.name,
        }, entry['varieties']);
        expect(CropRowTerminology.forCropCode(code).title, entry['row_term']);
        expect(
          FarmTaskType.bedCleaning.labelForCrop(code),
          'Mencuci ${entry['row_term']}',
        );
        controller.toggleVariety(controller.availableVarieties.first);
        expect(controller.canContinue, isTrue);
        final result = controller.buildResult();
        expect(result.cropCode, code);
        expect(result.varieties, [controller.availableVarieties.first]);
        final editController = ProjectFormController(initialData: result);
        expect(editController.selectedVarieties, result.varieties.toSet());
        editController.dispose();
      }
      expect(
        ProjectFormController(cropCode: 'unsupported').availableVarieties,
        isEmpty,
      );
    },
  );
}
