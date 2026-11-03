import 'package:flutter/material.dart';
import 'package:petani/project/views/control_product_list_view.dart';

class InsecticideListView extends StatelessWidget {
  const InsecticideListView({
    this.initialSelectedProductNames = const {},
    super.key,
  });

  final Set<String> initialSelectedProductNames;

  @override
  Widget build(BuildContext context) {
    return ControlProductListView(
      title: 'Senarai Racun Serangga',
      subtitle:
          'Pilihan bahan aktif racun serangga yang tersenarai di Malaysia.',
      assetPath: 'assets/data/insecticides.json',
      searchHint: 'Cari racun serangga atau bahan aktif',
      initialSelectedProductNames: initialSelectedProductNames,
    );
  }
}
