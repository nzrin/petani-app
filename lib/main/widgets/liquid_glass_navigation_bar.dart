import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:petani/main/models/main_destination.dart';

class LiquidGlassNavigationBar extends StatelessWidget {
  const LiquidGlassNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.profileAvatarAssetPath,
    super.key,
  });

  final List<MainDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String profileAvatarAssetPath;

  static const _barHeight = 65.0;
  static const _barRadius = _barHeight / 2;
  static const _selectionHeight = _barHeight - 12;
  static const _selectionRadius = _selectionHeight / 2;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_barRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x260B3D2E),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_barRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xC7FFFFFF),
                borderRadius: BorderRadius.circular(_barRadius),
                border: Border.all(color: const Color(0xE6FFFFFF), width: 1.2),
              ),
              child: SizedBox(
                height: _barHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const horizontalInset = 6.0;
                    final destinationWidth =
                        (constraints.maxWidth - (horizontalInset * 2)) /
                        destinations.length;

                    return Material(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            left:
                                horizontalInset +
                                (destinationWidth * selectedIndex),
                            top: 6,
                            bottom: 6,
                            width: destinationWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: DecoratedBox(
                                key: const Key('selected-navigation-pill'),
                                decoration: BoxDecoration(
                                  color: const Color(0xA8FFFFFF),
                                  borderRadius: BorderRadius.circular(
                                    _selectionRadius,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xF2FFFFFF),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x260B3D2E),
                                      blurRadius: 14,
                                      spreadRadius: 0,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 1,
                            left: 32,
                            right: 32,
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                color: const Color(0xE6FFFFFF),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(destinations.length, (
                              index,
                            ) {
                              final destination = destinations[index];
                              final isSelected = index == selectedIndex;

                              return Expanded(
                                child: Semantics(
                                  button: true,
                                  selected: isSelected,
                                  label: destination.label,
                                  child: InkWell(
                                    key: ValueKey<String>(
                                      'main-navigation-${destination.label}',
                                    ),
                                    onTap: () => onDestinationSelected(index),
                                    splashFactory: NoSplash.splashFactory,
                                    overlayColor: const WidgetStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      _selectionRadius,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          child: _DestinationImage(
                                            key: ValueKey<String>(
                                              '${destination.label}-$isSelected-'
                                              '${destination.usesProfileAvatar ? profileAvatarAssetPath : ''}',
                                            ),
                                            destination: destination,
                                            isSelected: isSelected,
                                            profileAvatarAssetPath:
                                                profileAvatarAssetPath,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'ProductSans',
                                            fontSize: 11,
                                            height: 1,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                          child: Text(destination.label),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationImage extends StatelessWidget {
  const _DestinationImage({
    required this.destination,
    required this.isSelected,
    required this.profileAvatarAssetPath,
    super.key,
  });

  final MainDestination destination;
  final bool isSelected;
  final String profileAvatarAssetPath;

  @override
  Widget build(BuildContext context) {
    if (destination.usesProfileAvatar) {
      return SizedBox(
        key: const ValueKey<String>('profile-navigation-avatar'),
        width: 32,
        height: 32,
        child: ClipOval(
          child: Image.asset(
            profileAvatarAssetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }

    return Image.asset(
      isSelected
          ? destination.selectedIconAssetPath!
          : destination.iconAssetPath!,
      key: ValueKey<String>(
        'navigation-image-${destination.label}-${isSelected ? 'selected' : 'normal'}',
      ),
      width: 27,
      height: 27,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
