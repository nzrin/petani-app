import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';

enum AppButtonVariant { filled, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.backgroundColor = AppColors.primaryAction,
    this.foregroundColor = Colors.white,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.height = 56,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
  }) : variant = AppButtonVariant.filled,
       borderColor = null;

  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.foregroundColor = AppColors.green,
    this.borderColor = AppColors.green,
    this.height = 56,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
  }) : variant = AppButtonVariant.outlined,
       backgroundColor = null,
       disabledBackgroundColor = null,
       disabledForegroundColor = null;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;

  static const _radius = 10.0;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon), const SizedBox(width: 8), Text(label)],
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: switch (variant) {
        AppButtonVariant.filled => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: disabledBackgroundColor,
            disabledForegroundColor: disabledForegroundColor,
            minimumSize: Size.fromHeight(height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: shape,
            textStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
          ),
          child: child,
        ),
        AppButtonVariant.outlined => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            minimumSize: Size.fromHeight(height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: borderColor ?? foregroundColor),
            shape: shape,
            textStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
          ),
          child: child,
        ),
      },
    );
  }
}
