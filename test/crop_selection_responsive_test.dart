import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/widgets/crop_selection_sheet.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'crop grid and list keep search, alphabetical order and selection at $width',
      (tester) async {
        final controller = CropSelectionController();
        addTearDown(controller.dispose);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: CropSelectionSheet(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.filteredCropOptions.map((crop) => crop.name), [
          'Bunga Kantan',
          'Cili',
          'Durian',
          'Getah',
          'Halia',
          'Jagung',
          'Kelapa',
          'Kesum',
          'Kunyit',
          'Limau Kasturi',
          'Limau Nipis',
          'Nanas',
          'Padi',
          'Pandan',
          'Pisang',
          'Rock Melon',
          'Sawit',
          'Serai',
          'Strawberi',
          'Tembikai',
          'Terung',
          'Timun',
          'Tomato',
          'Ubi Kayu',
          'Ubi Keledek',
        ]);
        final search = find.byKey(const Key('crop-search-field'));
        final tabs = find.byKey(const Key('crop-view-tabs'));
        expect(tester.getCenter(search).dy, tester.getCenter(tabs).dy);
        expect(
          tester.getTopLeft(tabs).dx,
          greaterThan(tester.getTopRight(search).dx),
        );
        await tester.tap(find.byKey(const Key('crop-list-tab')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('crop-list')), findsOneWidget);
        expect(find.byKey(const Key('crop-grid')), findsNothing);
        expect(
          tester.getTopLeft(find.byKey(const Key('crop-tile-Bunga Kantan'))).dy,
          lessThan(
            tester.getTopLeft(find.byKey(const Key('crop-tile-Getah'))).dy,
          ),
        );
        await tester.enterText(search, ' PA ');
        await tester.pumpAndSettle();
        expect(controller.filteredCropOptions.map((crop) => crop.name), [
          'Kelapa',
          'Padi',
          'Pandan',
        ]);
        await tester.tap(find.byKey(const Key('crop-tile-Padi')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('crop-grid-tab')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('crop-grid')), findsOneWidget);
        expect(controller.selectedCrop.code, 'rice');
        expect(
          tester.widget<TextField>(search).controller?.text ??
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller
                  .text,
          ' PA ',
        );
        await tester.enterText(search, 'zzzz');
        await tester.pumpAndSettle();
        expect(find.text('Tanaman tidak ditemui.'), findsOneWidget);
        await tester.tap(find.byKey(const Key('crop-list-tab')));
        await tester.enterText(search, '');
        await tester.pumpAndSettle();
        expect(controller.selectedCrop.code, 'rice');
        expect(find.byKey(const Key('crop-list')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('crop grid follows device class and orientation', (tester) async {
    final controller = CropSelectionController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    Future<void> expectColumns(Size size, int expectedColumns) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: CropSelectionSheet(controller: controller)),
        ),
      );
      await tester.pump();

      final grid = tester.widget<GridView>(find.byKey(const Key('crop-grid')));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, expectedColumns);
    }

    await expectColumns(const Size(390, 844), 2);
    await expectColumns(const Size(844, 390), 3);
    await expectColumns(const Size(834, 1194), 3);
    await expectColumns(const Size(1194, 834), 4);
  });
}
