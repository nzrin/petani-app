import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:petani/project/models/control_product.dart';

abstract interface class ControlProductRepository {
  Future<ControlProductCatalog> loadCatalog(String assetPath);
}

class AssetControlProductRepository implements ControlProductRepository {
  const AssetControlProductRepository();

  @override
  Future<ControlProductCatalog> loadCatalog(String assetPath) async {
    final jsonText = await rootBundle.loadString(assetPath);
    final json = jsonDecode(jsonText) as Map<String, Object?>;
    return ControlProductCatalog.fromJson(json);
  }
}
