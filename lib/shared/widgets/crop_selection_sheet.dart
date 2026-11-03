import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

const _cropSearchHeight = 45.0;

class CropSelectionSheet extends StatelessWidget {
  const CropSelectionSheet({required this.controller, super.key});

  final CropSelectionController controller;

  int _columnCount(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final isLandscape = size.width > size.height;

    if (isTablet) return isLandscape ? 4 : 3;
    return isLandscape ? 3 : 2;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardInsetPadding(
      child: FractionallySizedBox(
        heightFactor: 0.98,
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final selectedCrop = controller.selectedCrop;
              final crops = controller.filteredCropOptions;

              return Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5D9D7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                'Senarai Tanaman',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 24,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pilih jenis tanaman yang ingin direkodkan.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.mint,
                            foregroundColor: AppColors.forest,
                          ),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Tutup',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: _cropSearchHeight,
                            child: TextField(
                              key: const Key('crop-search-field'),
                              onChanged: controller.searchCrops,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Cari...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF1F3F2),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CropViewTabs(controller: controller),
                      ],
                    ),
                  ),
                  Expanded(
                    child: crops.isEmpty
                        ? const Center(
                            child: Text(
                              'Tanaman tidak ditemui.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          )
                        : !controller.showGrid
                        ? ListView.separated(
                            key: const Key('crop-list'),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                            itemCount: crops.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final crop = crops[index];
                              return _CropListTile(
                                crop: crop,
                                isSelected: crop == selectedCrop,
                                onTap: () => controller.selectCrop(crop),
                              );
                            },
                          )
                        : GridView.builder(
                            key: const Key('crop-grid'),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _columnCount(context),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemCount: crops.length,
                            itemBuilder: (context, index) {
                              final crop = crops[index];
                              return _CropGridTile(
                                crop: crop,
                                isSelected: crop == selectedCrop,
                                onTap: () => controller.selectCrop(crop),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    minimum: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: AppButton(
                        key: const Key('teruskan-button'),
                        label: 'Teruskan',
                        onPressed: controller.canContinue
                            ? () => Navigator.pop(context, selectedCrop)
                            : null,
                        disabledBackgroundColor: const Color(0xFFCCD4CF),
                        disabledForegroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CropViewTabs extends StatelessWidget {
  const _CropViewTabs({required this.controller});

  final CropSelectionController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('crop-view-tabs'),
      height: _cropSearchHeight,
      padding: const EdgeInsets.all(3),
      decoration: const ShapeDecoration(
        color: AppColors.mint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final grid in [true, false])
            Semantics(
              selected: controller.showGrid == grid,
              child: IconButton(
                key: Key(grid ? 'crop-grid-tab' : 'crop-list-tab'),
                tooltip: grid ? 'Paparan grid' : 'Paparan senarai',
                onPressed: () => controller.setShowGrid(grid),
                style: IconButton.styleFrom(
                  foregroundColor: controller.showGrid == grid
                      ? Colors.white
                      : AppColors.primaryAction,
                  backgroundColor: controller.showGrid == grid
                      ? AppColors.primaryAction
                      : Colors.transparent,
                  fixedSize: const Size.square(_cropSearchHeight - 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
                icon: grid
                    ? const Icon(Icons.grid_view_rounded, size: 20)
                    : Image.asset(
                        'assets/images/list.png',
                        width: 20,
                        height: 20,
                        color: controller.showGrid
                            ? AppColors.primaryAction
                            : Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CropListTile extends StatelessWidget {
  const _CropListTile({
    required this.crop,
    required this.isSelected,
    required this.onTap,
  });

  final CropOption crop;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>('crop-tile-${crop.name}'),
      button: true,
      selected: isSelected,
      enabled: crop.isAvailable,
      label: crop.isAvailable ? crop.name : '${crop.name}, akan datang',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFFDD24E)
                : const Color(0xFFE2E8E4),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: crop.isAvailable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: crop.isAvailable ? 1 : 0.38,
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 60,
                          child: _CropArtwork(crop: crop),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                crop.name,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                crop.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!crop.isAvailable)
                  const _ComingSoonPill()
                else
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryAction
                        : AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropGridTile extends StatelessWidget {
  const _CropGridTile({
    required this.crop,
    required this.isSelected,
    required this.onTap,
  });

  final CropOption crop;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>('crop-tile-${crop.name}'),
      button: true,
      selected: isSelected,
      enabled: crop.isAvailable,
      label: crop.isAvailable ? crop.name : '${crop.name}, akan datang',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: crop.isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFDD24E)
                    : const Color(0xFFE2E8E4),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _CropArtwork(crop: crop)),
                      const SizedBox(height: 6),
                      Text(
                        crop.name,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!crop.isAvailable)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                if (!crop.isAvailable)
                  Positioned(top: 0, right: 0, child: const _ComingSoonPill()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonPill extends StatelessWidget {
  const _ComingSoonPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDD24E),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Akan Datang',
        style: TextStyle(
          color: Color(0xFF987E2F),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CropArtwork extends StatelessWidget {
  const _CropArtwork({required this.crop});

  final CropOption crop;

  @override
  Widget build(BuildContext context) {
    final imagePath = crop.imagePath;
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.mint,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(crop.icon, color: AppColors.green, size: 34),
      ),
    );
  }
}
