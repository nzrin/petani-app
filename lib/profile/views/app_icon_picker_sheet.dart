import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/models/app_icon_option.dart';
import 'package:petani/profile/services/app_icon_service.dart';

Future<AppIconOption?> showAppIconPickerSheet({
  required BuildContext context,
  required AppIconOption selectedIcon,
  AppIconService service = const AppIconService(),
}) {
  return showModalBottomSheet<AppIconOption>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        AppIconPickerSheet(selectedIcon: selectedIcon, service: service),
  );
}

class AppIconPickerSheet extends StatefulWidget {
  const AppIconPickerSheet({
    required this.selectedIcon,
    required this.service,
    super.key,
  });

  final AppIconOption selectedIcon;
  final AppIconService service;

  @override
  State<AppIconPickerSheet> createState() => _AppIconPickerSheetState();
}

class _AppIconPickerSheetState extends State<AppIconPickerSheet> {
  String? _changingIconName;
  String? _errorMessage;

  Future<void> _selectIcon(AppIconOption option) async {
    if (_changingIconName != null) return;
    if (option.nativeName == widget.selectedIcon.nativeName) {
      Navigator.of(context).pop(option);
      return;
    }

    setState(() {
      _changingIconName = option.nativeName;
      _errorMessage = null;
    });
    try {
      await widget.service.setIcon(option.nativeName);
      if (!mounted) return;
      Navigator.of(context).pop(option);
    } on AppIconException {
      if (!mounted) return;
      setState(() {
        _changingIconName = null;
        _errorMessage = 'Ikon aplikasi tidak dapat ditukar. Cuba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FractionallySizedBox(
      heightFactor: 0.9,
      alignment: Alignment.bottomCenter,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Ikon Aplikasi',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Expanded(
              child: GridView.builder(
                key: const Key('app-icon-grid'),
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 5,
                  childAspectRatio: 0.68,
                ),
                itemCount: AppIconOption.options.length,
                itemBuilder: (context, index) {
                  final option = AppIconOption.options[index];
                  final isSelected =
                      option.nativeName == widget.selectedIcon.nativeName;
                  return _AppIconTile(
                    option: option,
                    isSelected: isSelected,
                    isChanging: _changingIconName == option.nativeName,
                    onTap: () => _selectIcon(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIconTile extends StatelessWidget {
  const _AppIconTile({
    required this.option,
    required this.isSelected,
    required this.isChanging,
    required this.onTap,
  });

  final AppIconOption option;
  final bool isSelected;
  final bool isChanging;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: isSelected,
      button: true,
      label: option.label,
      child: InkWell(
        key: ValueKey<String>('app-icon-${option.nativeName}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const iosCornerRadiusRatio = 0.2237;
                  final iconSide = constraints.maxWidth;
                  final selectionInset = isSelected ? 4.0 : 0.0;
                  final outerRadius = iconSide * iosCornerRadiusRatio;
                  final innerRadius =
                      (iconSide - (selectionInset * 2)) * iosCornerRadiusRatio;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.all(selectionInset),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(outerRadius),
                          border: isSelected
                              ? Border.all(color: AppColors.yellow, width: 3)
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(innerRadius),
                          child: Image.asset(
                            option.assetPath,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.primaryAction,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      if (isChanging)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(outerRadius),
                            ),
                            child: const Center(
                              child: SizedBox.square(
                                dimension: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? AppColors.primaryAction : colors.onSurface,
                fontSize: 13,
                height: 1.12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
