import 'package:flutter/material.dart';
import 'package:petani/project/views/control_product_list_view.dart';

class FungicideListView extends StatelessWidget {
  const FungicideListView({
    this.initialSelectedProductNames = const {},
    super.key,
  });

  final Set<String> initialSelectedProductNames;

  @override
  Widget build(BuildContext context) {
    return ControlProductListView(
      title: 'Senarai Racun Kulat',
      subtitle: 'Pilihan bahan aktif racun kulat yang tersenarai di Malaysia.',
      assetPath: 'assets/data/fungicides.json',
      searchHint: 'Cari racun kulat atau bahan aktif',
      initialSelectedProductNames: initialSelectedProductNames,
    );
  }
}
