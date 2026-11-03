import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';

Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String helpText = 'Pilih Masa Tugasan',
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    cancelText: 'Batal',
    confirmText: 'Pilih',
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: AppColors.primaryAction),
      ),
      child: child!,
    ),
  );
}
