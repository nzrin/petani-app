import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/controllers/control_product_list_controller.dart';
import 'package:petani/project/models/control_product.dart';
import 'package:petani/shared/widgets/app_button.dart';

class ProductCategoryTab {
  const ProductCategoryTab({required this.code, required this.label});

  final String code;
  final String label;
}

class ControlProductListView extends StatefulWidget {
  const ControlProductListView({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.searchHint,
    this.categoryTabs = const [],
    this.isPesticideCatalog = true,
    this.initialSelectedProductNames = const {},
    super.key,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final String searchHint;
  final List<ProductCategoryTab> categoryTabs;
  final bool isPesticideCatalog;
  final Set<String> initialSelectedProductNames;

  @override
  State<ControlProductListView> createState() => _ControlProductListViewState();
}

class _ControlProductListViewState extends State<ControlProductListView> {
  late final ControlProductListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ControlProductListController(
      assetPath: widget.assetPath,
      initialCategory: widget.categoryTabs.firstOrNull?.code,
      initialSelectedProductNames: widget.initialSelectedProductNames,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.navigationTitle.copyWith(
            color: Colors.white,
          ),
          title: Text(widget.title),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const Key('control-product-search-field'),
                        onChanged: _controller.setQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF1F3F2),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (widget.categoryTabs.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          key: const Key('fertilizer-category-tabs'),
                          children: [
                            for (
                              var index = 0;
                              index < widget.categoryTabs.length;
                              index++
                            ) ...[
                              if (index > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _CategoryPill(
                                  tab: widget.categoryTabs[index],
                                  selected:
                                      _controller.selectedCategory ==
                                      widget.categoryTabs[index].code,
                                  onTap: () => _controller.setCategory(
                                    widget.categoryTabs[index].code,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(child: _buildContent(context)),
              ],
            );
          },
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final count = _controller.selectedProductNames.length;
            return SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: AppButton(
                key: const Key('confirm-control-products-button'),
                label: count == 0 ? 'Pilih Produk' : 'Gunakan ($count)',
                onPressed: count == 0 || _controller.isLoading
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop(_controller.selectedProducts),
                disabledBackgroundColor: const Color(0xFFCCD4CF),
                disabledForegroundColor: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAction),
      );
    }
    if (_controller.error != null) {
      return _MessageState(
        icon: Icons.error_outline_rounded,
        title: 'Senarai tidak dapat dimuatkan',
        description: 'Cuba semula sebentar lagi.',
        actionLabel: 'Cuba Semula',
        onAction: _controller.load,
      );
    }

    final products = _controller.filteredProducts;
    if (products.isEmpty) {
      return const _MessageState(
        icon: Icons.search_off_rounded,
        title: 'Tiada produk ditemui',
        description: 'Cuba kata carian yang lain.',
      );
    }

    return ListView.separated(
      key: const Key('control-product-list'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: products.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SafetyNotice(isPesticide: widget.isPesticideCatalog);
        }
        final product = products[index - 1];
        return _ProductCard(
          product: product,
          selected: _controller.isSelected(product),
          onTap: () => _controller.toggleProduct(product),
        );
      },
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ProductCategoryTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryAction : const Color(0xFFF1F3F2),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        key: ValueKey<String>('product-category-${tab.code}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            tab.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({required this.isPesticide});

  final bool isPesticide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF987E2F),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPesticide
                  ? 'Semak nombor pendaftaran LRMP, tanaman, sasaran dan label semasa sebelum membeli atau menggunakan produk.'
                  : 'Pilih formulasi dan kadar berdasarkan keperluan tanaman, ujian tanah serta label pengilang.',
              style: const TextStyle(
                color: Color(0xFF705C21),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final ControlProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey<String>('control-product-${product.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primaryAction
                  : const Color(0xFFE1E5E3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected
                        ? AppColors.primaryAction
                        : const Color(0xFFBBC4BF),
                    size: 23,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _InfoPill(
                    key: ValueKey<String>(
                      'control-product-primary-detail-${product.name}',
                    ),
                    label: product.primaryDetail,
                    selected: selected,
                  ),
                  _InfoPill(
                    key: ValueKey<String>(
                      'control-product-secondary-detail-${product.name}',
                    ),
                    label: product.secondaryDetail,
                    isSecondary: true,
                    selected: selected,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    this.isSecondary = false,
    this.selected = false,
    super.key,
  });

  final String label;
  final bool isSecondary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isSecondary ? const Color(0xFFF1F3F2) : AppColors.mint,
        borderRadius: BorderRadius.circular(99),
        border: selected
            ? Border.all(
                color: isSecondary
                    ? const Color(0xFFB8C0BC)
                    : AppColors.primaryAction,
                width: 1,
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSecondary ? AppColors.muted : AppColors.forest,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
