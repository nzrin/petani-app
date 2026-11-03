import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/app_toast_controller.dart';

/// A non-blocking, content-sized toast shown above app navigation.
class AppToast extends StatelessWidget {
  const AppToast({required this.controller, super.key});

  /// Shows feedback above the current route, including pages with bottom bars.
  static void show(
    BuildContext context,
    String text, {
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration = AppToastController.visibleDuration,
  }) {
    final host = context.findAncestorStateOfType<_AppToastHostState>();
    assert(host != null, 'AppToastHost must wrap the app navigator.');
    host?._controller.show(
      text,
      isError: isError,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  final AppToastController controller;
  static const enterDuration = Duration(milliseconds: 320);
  static const exitDuration = Duration(milliseconds: 220);
  static const anchorGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stackAction = MediaQuery.textScalerOf(context).scale(14) > 18;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, message, _) => IgnorePointer(
        ignoring: message?.onAction == null,
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : enterDuration,
          reverseDuration: reduceMotion ? Duration.zero : exitDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.bottomCenter,
            children: [
              for (final child in previous)
                IgnorePointer(child: ExcludeSemantics(child: child)),
              ?current,
            ],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .35),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: message == null
              ? const SizedBox.shrink()
              : Semantics(
                  key: ObjectKey(message),
                  liveRegion: true,
                  label: message.text,
                  container: true,
                  explicitChildNodes: true,
                  child: Container(
                    key: const ValueKey('app-toast'),
                    constraints: const BoxConstraints(
                      maxWidth: 340,
                      minHeight: 46,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: message.onAction == null ? 12 : 2,
                    ),
                    decoration: const ShapeDecoration(
                      color: AppColors.forest,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.primaryAction),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x280b3d2e),
                          blurRadius: 16,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              message.isError
                                  ? Icons.error_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 20,
                              color: message.isError
                                  ? const Color(0xffffcfbd)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: ExcludeSemantics(
                                child: Text(
                                  message.text,
                                  maxLines: message.onAction == null ? null : 4,
                                  overflow: message.onAction == null
                                      ? TextOverflow.clip
                                      : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'ProductSans',
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                            if (message.onAction != null && !stackAction) ...[
                              const SizedBox(width: 8),
                              _ToastAction(
                                label: message.actionLabel!,
                                onPressed: () =>
                                    controller.performAction(message),
                              ),
                            ],
                          ],
                        ),
                        if (message.onAction != null && stackAction)
                          _ToastAction(
                            label: message.actionLabel!,
                            onPressed: () => controller.performAction(message),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ToastAction extends StatelessWidget {
  const _ToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: TextButton(
      key: const ValueKey('app-toast-action'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mint,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    ),
  );
}

/// One toast controller shared by every route and bottom sheet in the app.
class AppToastHost extends StatefulWidget {
  const AppToastHost({required this.child, super.key});

  final Widget child;

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost> {
  final _controller = AppToastController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    // Reserve the 65px navigation pill and its minimum 12px bottom margin.
    final bottom = keyboardInset > 0
        ? keyboardInset + AppToast.anchorGap
        : 65 + math.max(safeBottom, 12) + AppToast.anchorGap;
    return AppToastOverlay(
      controller: _controller,
      bottom: bottom,
      child: widget.child,
    );
  }
}

/// Keeps list-page feedback fixed above navigation, independent of scrolling.
class AppToastOverlay extends StatelessWidget {
  const AppToastOverlay({
    required this.controller,
    required this.bottom,
    required this.child,
    super.key,
  });

  final AppToastController controller;
  final double bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      Positioned(
        left: 20,
        right: 20,
        bottom: bottom,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: AppToast(controller: controller),
          ),
        ),
      ),
    ],
  );
}
