import 'package:flutter/material.dart';
import 'package:petani/project/views/control_product_list_view.dart';

class FertilizerListView extends StatelessWidget {
  const FertilizerListView({
    this.initialSelectedProductNames = const {},
    super.key,
  });

  final Set<String> initialSelectedProductNames;

  @override
  Widget build(BuildContext context) {
    return ControlProductListView(
      title: 'Senarai Baja',
      subtitle: 'Pilih jenis baja mengikut keperluan tanaman anda.',
      assetPath: 'assets/data/fertilizers.json',
      searchHint: 'Cari baja atau kandungan nutrien',
      isPesticideCatalog: false,
      initialSelectedProductNames: initialSelectedProductNames,
      categoryTabs: [
        ProductCategoryTab(code: 'liquid', label: 'Baja Cecair'),
        ProductCategoryTab(code: 'granular', label: 'Baja Butiran'),
      ],
    );
  }
}
