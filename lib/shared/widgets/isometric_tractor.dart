import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../painters/isometric_tractor_painter.dart';

/// Resolution-independent artwork shared by every empty state.
class IsometricTractor extends StatefulWidget {
  const IsometricTractor({
    this.size = defaultSize,
    this.topSpacing = defaultTopSpacing,
    super.key,
  });

  /// Shared width of the complete tractor-and-soil illustration on every page.
  static const double defaultSize = 320;

  /// Space above the tractor rooftop, in logical pixels.
  static const double defaultTopSpacing = 16;

  final double topSpacing;

  /// Space below the soil edge, before the empty-state title.
  static const double bottomSpacing = 16;

  /// Preferred width. Height follows the artwork's natural proportions.
  final double size;

  @override
  State<IsometricTractor> createState() => _IsometricTractorState();
}

class _IsometricTractorState extends State<IsometricTractor>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;
  double _resumedAt = 0;
  bool _visible = true;
  bool _reduceMotion = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _ticker = createTicker((elapsed) {
      _seconds.value = _resumedAt + elapsed.inMicroseconds / 1000000;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _updatePlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updatePlayback();
  }

  void _updatePlayback() {
    if (_visible && !_reduceMotion && _foreground) {
      if (!_ticker.isActive) {
        _resumedAt = _seconds.value;
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: widget.topSpacing),
            AspectRatio(
              aspectRatio: IsometricTractorPainter.aspectRatio,
              child: CustomPaint(
                painter: IsometricTractorPainter(animation: _seconds),
              ),
            ),
            const SizedBox(height: IsometricTractor.bottomSpacing),
          ],
        ),
      ),
    ),
  );
}
