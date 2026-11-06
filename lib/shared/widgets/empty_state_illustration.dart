import 'package:flutter/material.dart';

/// Static artwork shared by empty states. No ticker or custom painter is used.
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    this.size = defaultSize,
    this.topSpacing = defaultTopSpacing,
    super.key,
  });

  static const assetPath = 'assets/images/empty_state_wall.png';
  static const double defaultSize = 220;
  static const double defaultTopSpacing = 16;
  static const double bottomSpacing = 16;

  final double size;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    // Bound decoded memory to the preferred display size, at most 1000² pixels.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
      1,
      1000,
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topSpacing),
            AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                cacheWidth: pixels,
                filterQuality: FilterQuality.medium,
              ),
            ),
            const SizedBox(height: bottomSpacing),
          ],
        ),
      ),
    );
  }
}
