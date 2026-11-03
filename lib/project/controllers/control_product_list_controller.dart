import 'package:flutter/foundation.dart';
import 'package:petani/project/models/control_product.dart';
import 'package:petani/project/repositories/control_product_repository.dart';

class ControlProductListController extends ChangeNotifier {
  ControlProductListController({
    required this.assetPath,
    this._repository = const AssetControlProductRepository(),
    String? initialCategory,
    Set<String> initialSelectedProductNames = const {},
  }) : selectedCategory = initialCategory,
       selectedProductNames = {...initialSelectedProductNames};

  final String assetPath;
  final ControlProductRepository _repository;

  ControlProductCatalog? catalog;
  String query = '';
  String? selectedCategory;
  final Set<String> selectedProductNames;
  bool isLoading = false;
  Object? error;

  List<ControlProduct> get filteredProducts {
    final products = catalog?.products ?? const <ControlProduct>[];
    return products
        .where(
          (product) =>
              (selectedCategory == null ||
                  product.category == selectedCategory) &&
              product.matches(query),
        )
        .toList(growable: false);
  }

  List<ControlProduct> get selectedProducts {
    final products = catalog?.products ?? const <ControlProduct>[];
    return products
        .where((product) => selectedProductNames.contains(product.name))
        .toList(growable: false);
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      catalog = await _repository.loadCatalog(assetPath);
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    if (query == value) return;
    query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    if (selectedCategory == value) return;
    selectedCategory = value;
    notifyListeners();
  }

  bool isSelected(ControlProduct product) {
    return selectedProductNames.contains(product.name);
  }

  void toggleProduct(ControlProduct product) {
    if (!selectedProductNames.add(product.name)) {
      selectedProductNames.remove(product.name);
    }
    notifyListeners();
  }
}
