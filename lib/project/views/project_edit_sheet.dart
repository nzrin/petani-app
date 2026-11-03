import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

class ProjectEditResult {
  const ProjectEditResult({required this.projectName, required this.location});

  final String projectName;
  final String location;
}

Future<ProjectEditResult?> showProjectEditSheet({
  required BuildContext context,
  required String projectName,
  required String location,
}) {
  return showModalBottomSheet<ProjectEditResult>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ProjectEditSheet(projectName: projectName, location: location),
  );
}

class _ProjectEditSheet extends StatefulWidget {
  const _ProjectEditSheet({required this.projectName, required this.location});

  final String projectName;
  final String location;

  @override
  State<_ProjectEditSheet> createState() => _ProjectEditSheetState();
}

class _ProjectEditSheetState extends State<_ProjectEditSheet> {
  late final TextEditingController _projectNameController;
  late final TextEditingController _locationController;
  int _currentStep = 0;

  bool get _canContinue => _currentStep == 0
      ? _projectNameController.text.trim().isNotEmpty
      : _locationController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController(text: widget.projectName);
    _locationController = TextEditingController(text: widget.location);
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_canContinue) return;
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }
    Navigator.pop(
      context,
      ProjectEditResult(
        projectName: _projectNameController.text.trim(),
        location: _locationController.text.trim(),
      ),
    );
  }

  void _handleLeadingAction() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep = 0);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.94;

    return KeyboardInsetPadding(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.hardEdge,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Material(
              key: const Key('project-edit-sheet'),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5D9D7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            'Langkah ${_currentStep + 1} daripada 2',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('project-edit-leading-button'),
                          onPressed: _handleLeadingAction,
                          tooltip: _currentStep == 0 ? 'Tutup' : 'Kembali',
                          icon: Icon(
                            _currentStep == 0
                                ? Icons.close_rounded
                                : Icons.arrow_back_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(2, (index) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: 4,
                            margin: EdgeInsets.only(right: index == 0 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: index <= _currentStep
                                  ? AppColors.green
                                  : const Color(0xFFE3E8E5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _currentStep == 0
                          ? _ProjectEditStep(
                              key: const ValueKey<int>(0),
                              title: 'Namakan projek anda',
                              description:
                                  'Gunakan nama yang mudah dikenali untuk '
                                  'pengurusan tanaman ini.',
                              fieldKey: const Key('project-edit-name-field'),
                              hintText: 'Projek Nanas 2026',
                              controller: _projectNameController,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _continue(),
                            )
                          : _ProjectEditStep(
                              key: const ValueKey<int>(1),
                              title: 'Di manakah projek ini?',
                              description:
                                  'Masukkan lokasi ladang atau kawasan tanaman.',
                              fieldKey: const Key(
                                'project-edit-location-field',
                              ),
                              hintText: 'Pontian, Johor',
                              controller: _locationController,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _continue(),
                            ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: AppButton(
                      key: Key(
                        _currentStep == 0
                            ? 'continue-project-edit-button'
                            : 'save-project-edit-button',
                      ),
                      label: _currentStep == 0
                          ? 'Seterusnya'
                          : 'Simpan Perubahan',
                      onPressed: _canContinue ? _continue : null,
                      disabledBackgroundColor: const Color(0xFFCCD4CF),
                      disabledForegroundColor: Colors.white,
                    ),
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

class _ProjectEditStep extends StatelessWidget {
  const _ProjectEditStep({
    required super.key,
    required this.title,
    required this.description,
    required this.fieldKey,
    required this.hintText,
    required this.controller,
    required this.textInputAction,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String title;
  final String description;
  final Key fieldKey;
  final String hintText;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 10),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 42),
        TextField(
          key: fieldKey,
          controller: controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFAAB2AE),
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD7DDDA)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.green, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
