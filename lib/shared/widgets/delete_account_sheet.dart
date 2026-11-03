import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DeleteAccountSheet(),
  );
  return result ?? false;
}

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  static const _confirmationWord = 'PADAM';

  final _confirmationController = TextEditingController();

  bool get _isConfirmed =>
      _confirmationController.text.trim().toUpperCase() == _confirmationWord;

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(_refreshConfirmation);
  }

  void _refreshConfirmation() => setState(() {});

  @override
  void dispose() {
    _confirmationController
      ..removeListener(_refreshConfirmation)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return KeyboardInsetPadding(
      child: Material(
        key: const Key('delete-account-confirmation-sheet'),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
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
                  const SizedBox(height: 28),
                  Image.asset(
                    'assets/images/trash.png',
                    key: const Key('delete-account-confirmation-image'),
                    width: 124,
                    height: 124,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Padam akaun secara kekal?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profil, projek, plot, tanaman, tugasan dan data awan '
                    'anda akan dipadam secara kekal. Tindakan ini tidak '
                    'boleh dibuat asal.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    key: const Key('delete-account-confirmation-field'),
                    controller: _confirmationController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_isConfirmed) Navigator.pop(context, true);
                    },
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Taip PADAM untuk mengesahkan',
                      hintStyle: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.62),
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE12D3B),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    key: const Key('delete-account-permanently-button'),
                    label: 'Padam akaun secara kekal',
                    backgroundColor: const Color(0xFFE12D3B),
                    disabledBackgroundColor: const Color(0xFFF3BDC2),
                    disabledForegroundColor: Colors.white,
                    onPressed: _isConfirmed
                        ? () => Navigator.pop(context, true)
                        : null,
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
