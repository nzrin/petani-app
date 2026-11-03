import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_toast_message.dart';

/// A new message replaces the visible one and renews its lifetime.
class AppToastController extends ValueNotifier<AppToastMessage?> {
  AppToastController() : super(null);

  static const visibleDuration = Duration(seconds: 3);
  Timer? _timer;

  void show(
    String text, {
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration = visibleDuration,
  }) {
    _timer?.cancel();
    value = AppToastMessage(
      text,
      isError: isError,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    _timer = duration == null ? null : Timer(duration, dismiss);
  }

  void performAction(AppToastMessage message) {
    if (!identical(value, message) || message.onAction == null) return;
    dismiss();
    message.onAction!();
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    value = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
