import 'package:flutter/foundation.dart';

@immutable
class AppToastMessage {
  const AppToastMessage(
    this.text, {
    this.isError = false,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String text;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;
}
