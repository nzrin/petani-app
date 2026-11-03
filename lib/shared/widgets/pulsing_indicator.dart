import 'package:flutter/material.dart';

class PulsingIndicator extends StatefulWidget {
  const PulsingIndicator({required this.color, super.key, this.size = 15});

  final Color color;
  final double size;

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
        builder: (context, child) {
          final pulse = disableAnimations
              ? 1.0
              : Curves.easeInOut.transform(_controller.value);
          return Transform.scale(scale: .82 + (.18 * pulse), child: child);
        },
      ),
    );
  }
}
