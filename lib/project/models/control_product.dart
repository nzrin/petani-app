class ControlProductCatalog {
  const ControlProductCatalog({
    required this.products,
    this.source,
    this.sourceUrl,
    this.lastReviewed,
  });

  factory ControlProductCatalog.fromJson(Map<String, Object?> json) {
    final rawProducts = json['products'] as List<Object?>? ?? const [];
    return ControlProductCatalog(
      products: rawProducts
          .whereType<Map<String, Object?>>()
          .map(ControlProduct.fromJson)
          .toList(growable: false),
      source: json['source'] as String?,
      sourceUrl: json['source_url'] as String?,
      lastReviewed: json['last_reviewed'] as String?,
    );
  }

  final List<ControlProduct> products;
  final String? source;
  final String? sourceUrl;
  final String? lastReviewed;
}

class ControlProduct {
  const ControlProduct({
    required this.name,
    required this.primaryDetail,
    required this.secondaryDetail,
    required this.description,
    this.category,
  });

  factory ControlProduct.fromJson(Map<String, Object?> json) {
    return ControlProduct(
      name: json['name'] as String? ?? '',
      primaryDetail: json['primary_detail'] as String? ?? '',
      secondaryDetail: json['secondary_detail'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
    );
  }

  final String name;
  final String primaryDetail;
  final String secondaryDetail;
  final String description;
  final String? category;

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return name.toLowerCase().contains(normalizedQuery) ||
        primaryDetail.toLowerCase().contains(normalizedQuery) ||
        secondaryDetail.toLowerCase().contains(normalizedQuery) ||
        description.toLowerCase().contains(normalizedQuery);
  }
}
