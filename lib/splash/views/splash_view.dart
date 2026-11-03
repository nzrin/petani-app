import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashView extends StatefulWidget {
  const SplashView({
    required this.nextPageBuilder,
    this.initializeApp,
    super.key,
  });

  final WidgetBuilder nextPageBuilder;
  final Future<void> Function()? initializeApp;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const _splashGreen = Color(0xFF016B3D);
  static const _pulseMilliseconds = 3400;
  static const _zoomMilliseconds = 650;
  static const _pageFadeDuration = Duration(milliseconds: 280);
  static const _totalDuration = Duration(
    milliseconds: _pulseMilliseconds + _zoomMilliseconds,
  );
  static const _pulseEnd =
      _pulseMilliseconds / (_pulseMilliseconds + _zoomMilliseconds);

  late final AnimationController _controller;
  late final Future<void> _initialization;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _initialization = Future<void>.sync(() => widget.initializeApp?.call());
    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..addStatusListener(_handleAnimationStatus)
      ..forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _isFinishing || !mounted) {
      return;
    }
    _isFinishing = true;
    _finishSplash();
  }

  Future<void> _finishSplash() async {
    await _initialization;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextPageBuilder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: _pageFadeDuration,
        reverseTransitionDuration: _pageFadeDuration,
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _splashGreen,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _splashGreen,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final longestSide = math.max(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final imageSize = math.min(shortestSide * 0.464, 304.0);
            final finalScale = math.max(4.8, (longestSide / imageSize) * 1.55);

            return SizedBox.expand(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final value = _controller.value;
                  final isPulsing = value <= _pulseEnd;
                  final pulseProgress = isPulsing ? value / _pulseEnd : 1.0;
                  final pulseWave = math.sin(pulseProgress * math.pi * 6 * 1.2);
                  final settleProgress = ((pulseProgress - 0.88) / 0.12).clamp(
                    0.0,
                    1.0,
                  );
                  final pulseEnvelope =
                      1 - Curves.easeOutCubic.transform(settleProgress);
                  final pulseScale = 1 + (pulseWave * 0.045 * pulseEnvelope);
                  final zoomProgress = isPulsing
                      ? 0.0
                      : Curves.easeInCubic.transform(
                          (value - _pulseEnd) / (1 - _pulseEnd),
                        );
                  final imageScale = isPulsing
                      ? pulseScale
                      : 1 + ((finalScale - 1) * zoomProgress);
                  final imageOpacity = 1 - (zoomProgress * 0.28);

                  return Center(
                    child: Opacity(
                      opacity: imageOpacity,
                      child: Transform.scale(
                        scale: imageScale,
                        child: FractionalTranslation(
                          translation: const Offset(0, -0.0165),
                          child: Semantics(
                            label: 'Logo Petani',
                            image: true,
                            child: Image.asset(
                              'assets/images/icon_head_1000.png',
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
