import 'package:flutter/material.dart';

/// Keeps a bottom sheet attached to the system keyboard without adding a
/// second animation on top of the platform keyboard transition.
class KeyboardInsetPadding extends StatelessWidget {
  const KeyboardInsetPadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }
}
