import 'package:flutter/material.dart';
import 'package:petani/project/views/control_product_list_view.dart';

class HerbicideListView extends StatelessWidget {
  const HerbicideListView({
    this.initialSelectedProductNames = const {},
    super.key,
  });

  final Set<String> initialSelectedProductNames;

  @override
  Widget build(BuildContext context) {
    return ControlProductListView(
      title: 'Senarai Racun Rumpai',
      subtitle: 'Pilihan bahan aktif racun rumpai yang tersenarai di Malaysia.',
      assetPath: 'assets/data/herbicides.json',
      searchHint: 'Cari racun rumpai atau bahan aktif',
      initialSelectedProductNames: initialSelectedProductNames,
    );
  }
}
