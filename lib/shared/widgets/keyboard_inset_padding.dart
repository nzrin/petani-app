import 'package:flutter/material.dart';

/// Keeps a bottom sheet attached to the system keyboard without adding a
/// second animation on top of the platform keyboard transition.
class KeyboardInsetPadding extends StatelessWidget {
  const KeyboardInsetPadding({
    required this.child,
    this.backgroundColor = Colors.white,
    super.key,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
        // Fill only the keyboard area so its rounded top corners cannot show
        // the route behind it. The sheet's own top corners stay transparent.
        if (bottomInset > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomInset,
            child: IgnorePointer(
              child: ColoredBox(
                key: const Key('sheet-keyboard-background'),
                color: backgroundColor,
              ),
            ),
          ),
      ],
    );
  }
}
