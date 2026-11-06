import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';

Future<bool> showAppConfirmationSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmLabel,
  String? imagePath,
  Color confirmColor = AppColors.primaryAction,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => KeyboardInsetPadding(
      child: AppConfirmationSheet(
        imagePath: imagePath,
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      ),
    ),
  );
  return result ?? false;
}

class AppConfirmationSheet extends StatelessWidget {
  const AppConfirmationSheet({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.confirmColor,
    this.imagePath,
    super.key,
  });

  final String? imagePath;
  final String title;
  final String description;
  final String confirmLabel;
  final Color confirmColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('app-confirmation-sheet'),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5D9D7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                SizedBox(height: imagePath == null ? 26 : 32),
                if (imagePath case final imagePath?) ...[
                  Image.asset(
                    imagePath,
                    key: const Key('app-confirmation-sheet-image'),
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 36),
                AppButton(
                  key: const Key('app-confirmation-sheet-confirm-button'),
                  label: confirmLabel,
                  backgroundColor: confirmColor,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
