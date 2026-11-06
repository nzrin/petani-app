import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/controllers/project_form_controller.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/shared/models/crop_harvest_estimate.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/date_picker_sheet.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

class ProjectFormSheet extends StatefulWidget {
  const ProjectFormSheet({
    super.key,
    this.cropCode = 'pineapple',
    this.suggestions = const ProjectFormSuggestions(),
    this.fixedProject,
    this.initialData,
    this.onDelete,
    this.requireExistingProject = false,
  });

  final String cropCode;
  final ProjectFormSuggestions suggestions;
  final ExistingProjectSuggestion? fixedProject;
  final ProjectFormData? initialData;
  final Future<bool> Function()? onDelete;
  final bool requireExistingProject;

  @override
  State<ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<ProjectFormSheet> {
  late final ProjectFormController _controller;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = ProjectFormController(
      cropCode: widget.cropCode,
      suggestions: widget.suggestions,
      fixedProject: widget.fixedProject,
      initialData: widget.initialData,
      requireExistingProject: widget.requireExistingProject,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLeadingAction() {
    FocusScope.of(context).unfocus();
    if (_controller.isFirstVisibleStep) {
      Navigator.pop(context);
      return;
    }
    _controller.previousStep();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (_controller.isLastStep) {
      Navigator.pop(context, _controller.buildResult());
      return;
    }
    _controller.nextStep();
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null || _isDeleting) return;
    FocusScope.of(context).unfocus();
    setState(() => _isDeleting = true);
    final deleted = await onDelete();
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isDeleting = false);
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    final date = await showAppDatePickerSheet(
      context: context,
      initialDate: _controller.plantedAt,
    );
    if (!mounted || date == null) return;
    _controller.setPlantedAt(date);
  }

  @override
  Widget build(BuildContext context) {
    final fullSheetHeight = MediaQuery.sizeOf(context).height * 0.94;

    return KeyboardInsetPadding(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final useFullHeight = _controller.isLastStep;
          final step = KeyedSubtree(
            key: ValueKey<int>(_controller.currentStep),
            child: _buildStep(),
          );

          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: AnimatedSize(
              key: const Key('project-form-sheet-surface'),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.hardEdge,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: fullSheetHeight),
                child: SizedBox(
                  height: useFullHeight ? fullSheetHeight : null,
                  child: Material(
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: Column(
                      mainAxisSize: useFullHeight
                          ? MainAxisSize.max
                          : MainAxisSize.min,
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
                                  'Langkah ${_controller.visibleStepIndex + 1} '
                                  'daripada ${_controller.visibleStepCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const Key('project-form-leading-button'),
                                onPressed: _handleLeadingAction,
                                icon: Icon(
                                  _controller.isFirstVisibleStep
                                      ? Icons.close_rounded
                                      : Icons.arrow_back_rounded,
                                ),
                                color: AppColors.ink,
                                tooltip: _controller.isFirstVisibleStep
                                    ? 'Tutup'
                                    : 'Kembali',
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: List.generate(
                              _controller.visibleStepCount,
                              (index) {
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    height: 4,
                                    margin: EdgeInsets.only(
                                      right:
                                          index ==
                                              _controller.visibleStepCount - 1
                                          ? 0
                                          : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          index <= _controller.visibleStepIndex
                                          ? AppColors.green
                                          : const Color(0xFFE3E8E5),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (useFullHeight)
                          Expanded(child: step)
                        else
                          Flexible(fit: FlexFit.loose, child: step),
                        SafeArea(
                          top: false,
                          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(
                            children: [
                              if (widget.onDelete != null) ...[
                                Expanded(
                                  child: AppButton.outlined(
                                    key: const Key('delete-plot-button'),
                                    label: 'Padam',
                                    foregroundColor: const Color(0xFFB3261E),
                                    borderColor: const Color(0xFFB3261E),
                                    onPressed: _isDeleting ? null : _delete,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: widget.onDelete == null ? 1 : 2,
                                child: AppButton(
                                  key: const Key(
                                    'project-form-continue-button',
                                  ),
                                  label: _controller.isLastStep
                                      ? _controller.isEditing
                                            ? 'Simpan Perubahan'
                                            : _controller
                                                  .isAddingPlotToExistingProject
                                            ? 'Simpan Plot'
                                            : 'Simpan Projek'
                                      : 'Seterusnya',
                                  onPressed:
                                      _controller.canContinue && !_isDeleting
                                      ? _continue
                                      : null,
                                  disabledBackgroundColor: const Color(
                                    0xFFCCD4CF,
                                  ),
                                  disabledForegroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep() {
    return switch (_controller.currentStep) {
      0 => _TextFieldStep(
        title: widget.requireExistingProject
            ? 'Pilih projek anda'
            : 'Namakan projek anda',
        description: widget.requireExistingProject
            ? 'Pilih projek yang akan menempatkan plot baharu ini.'
            : 'Gunakan nama yang mudah dikenali untuk pengurusan tanaman ini.',
        fieldName: 'Nama Projek',
        hintText: widget.requireExistingProject
            ? 'Cari nama projek'
            : 'Projek Nanas 2026',
        controller: _controller.projectNameController,
        suggestions: _controller.suggestions.existingProjects
            .map((project) => project.name)
            .toList(growable: false),
        onSuggestionSelected: _controller.selectExistingProjectByName,
        textInputAction: TextInputAction.next,
        onChanged: _controller.updateProjectName,
        onSubmitted: (_) => _controller.canContinue ? _continue() : null,
      ),
      1 => _TextFieldStep(
        title: 'Di manakah projek ini?',
        description: 'Masukkan lokasi ladang atau kawasan tanaman.',
        fieldName: 'Lokasi',
        hintText: 'Pontian, Johor',
        controller: _controller.locationController,
        suggestions: _controller.suggestions.locations,
        onSuggestionSelected: _controller.selectLocation,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _controller.refresh(),
        onSubmitted: (_) => _controller.canContinue ? _continue() : null,
      ),
      2 => _TextFieldStep(
        title: 'Namakan plot tanaman',
        description: 'Nama plot membantu anda membezakan kawasan tanaman.',
        fieldName: 'Nama Plot',
        hintText: 'Plot A001',
        controller: _controller.plotNameController,
        suggestions: const [],
        onSuggestionSelected: (_) {},
        errorText: _controller.plotNameAlreadyExists
            ? 'Nama plot ini sudah digunakan dalam projek ini.'
            : null,
        textInputAction: TextInputAction.done,
        onChanged: (_) => _controller.refresh(),
        onSubmitted: (_) => _controller.canContinue ? _continue() : null,
      ),
      _ => _ProjectDetailsStep(
        controller: _controller,
        onSelectDate: _selectDate,
      ),
    };
  }
}

class _TextFieldStep extends StatelessWidget {
  const _TextFieldStep({
    required this.title,
    required this.description,
    required this.fieldName,
    required this.hintText,
    required this.controller,
    required this.suggestions,
    required this.onSuggestionSelected,
    required this.textInputAction,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
  });

  final String title;
  final String description;
  final String fieldName;
  final String hintText;
  final TextEditingController controller;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionSelected;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = _rankSuggestions(suggestions, controller.text);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 10),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 42),
            TextField(
              key: ValueKey<String>('project-form-$fieldName'),
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
                errorText: errorText,
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
            if (visibleSuggestions.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  key: ValueKey<String>('project-form-$fieldName-suggestions'),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: visibleSuggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = visibleSuggestions[index];
                    final isSelected =
                        _normalizeSuggestion(controller.text) ==
                        _normalizeSuggestion(suggestion);
                    return ChoiceChip(
                      key: ValueKey<String>(
                        'project-form-$fieldName-suggestion-$suggestion',
                      ),
                      label: Text(suggestion),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) => onSuggestionSelected(suggestion),
                      selectedColor: AppColors.mint,
                      backgroundColor: const Color(0xFFF1F3F2),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.green
                            : const Color(0xFFDDE3E0),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.forest : AppColors.muted,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: const StadiumBorder(),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SuggestionMatch {
  const _SuggestionMatch(this.value, this.score);

  final String value;
  final double score;
}

List<String> _rankSuggestions(List<String> suggestions, String input) {
  const resultLimit = 10;
  final uniqueSuggestions = <String, String>{};
  for (final suggestion in suggestions) {
    uniqueSuggestions.putIfAbsent(
      _normalizeSuggestion(suggestion),
      () => suggestion,
    );
  }

  final query = _normalizeSuggestion(input);
  if (query.isEmpty) {
    return uniqueSuggestions.values.take(resultLimit).toList(growable: false);
  }

  final matches = <_SuggestionMatch>[];
  for (final entry in uniqueSuggestions.entries) {
    final score = _suggestionScore(entry.key, query);
    if (score != null) {
      matches.add(_SuggestionMatch(entry.value, score));
    }
  }

  matches.sort((first, second) {
    final scoreOrder = second.score.compareTo(first.score);
    if (scoreOrder != 0) return scoreOrder;
    return first.value.toLowerCase().compareTo(second.value.toLowerCase());
  });

  return matches
      .take(resultLimit)
      .map((match) => match.value)
      .toList(growable: false);
}

String _normalizeSuggestion(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

double? _suggestionScore(String candidate, String query) {
  if (candidate == query) return 1000.0;
  if (candidate.startsWith(query)) {
    return 900.0 - (candidate.length - query.length);
  }

  final containsAt = candidate.indexOf(query);
  if (containsAt >= 0) return 800.0 - containsAt;

  final startsAtWord = candidate
      .split(' ')
      .any((word) => word.startsWith(query));
  if (startsAtWord) return 750.0;

  if (query.length < 3) return null;
  final longestLength = candidate.length > query.length
      ? candidate.length
      : query.length;
  final similarity =
      1 - (_levenshteinDistance(candidate, query) / longestLength);
  return similarity >= 0.65 ? similarity * 700 : null;
}

int _levenshteinDistance(String first, String second) {
  if (first == second) return 0;
  if (first.isEmpty) return second.length;
  if (second.isEmpty) return first.length;

  var previous = List<int>.generate(second.length + 1, (index) => index);
  for (var firstIndex = 0; firstIndex < first.length; firstIndex++) {
    final current = List<int>.filled(second.length + 1, 0);
    current[0] = firstIndex + 1;
    for (var secondIndex = 0; secondIndex < second.length; secondIndex++) {
      final substitutionCost =
          first.codeUnitAt(firstIndex) == second.codeUnitAt(secondIndex)
          ? 0
          : 1;
      final insertion = current[secondIndex] + 1;
      final deletion = previous[secondIndex + 1] + 1;
      final substitution = previous[secondIndex] + substitutionCost;
      current[secondIndex + 1] = insertion < deletion
          ? (insertion < substitution ? insertion : substitution)
          : (deletion < substitution ? deletion : substitution);
    }
    previous = current;
  }
  return previous.last;
}

class _ProjectDetailsStep extends StatelessWidget {
  const _ProjectDetailsStep({
    required this.controller,
    required this.onSelectDate,
  });

  final ProjectFormController controller;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) {
    final rowTerminology = CropRowTerminology.forCropCode(controller.cropCode);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lengkapkan tanaman anda',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih tanaman, ${controller.varietyFieldTitle.toLowerCase()}, '
            'jumlah ${rowTerminology.lowercase} dan '
            'tarikh mula menanam.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Tanaman'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProjectFormController.supportedCrops.entries
                .map((crop) {
                  final isSelected = controller.cropCode == crop.key;
                  return ChoiceChip(
                    key: ValueKey<String>('project-form-crop-${crop.key}'),
                    label: Text(crop.value),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) => controller.selectCrop(crop.key),
                    selectedColor: AppColors.mint,
                    backgroundColor: const Color(0xFFF4F6F5),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.green
                          : const Color(0xFFDDE3E0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.forest : AppColors.muted,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    shape: const StadiumBorder(),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 26),
          _SectionLabel(controller.varietyFieldTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.availableVarieties.map((variety) {
              final isSelected = controller.selectedVarieties.contains(variety);
              return ChoiceChip(
                label: Text(variety.label),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) => controller.toggleVariety(variety),
                selectedColor: AppColors.mint,
                backgroundColor: const Color(0xFFF4F6F5),
                side: BorderSide(
                  color: isSelected ? AppColors.green : const Color(0xFFDDE3E0),
                  width: isSelected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.forest : AppColors.muted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: const StadiumBorder(),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
          _SectionLabel(rowTerminology.title),
          const SizedBox(height: 5),
          Text(
            'Jumlah ${rowTerminology.lowercase} untuk plot ini.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _RaisedBedSlider(controller: controller),
          const SizedBox(height: 12),
          TextField(
            key: const Key('custom-raised-bed-field'),
            controller: controller.customRaisedBedController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => controller.refresh(),
            decoration: InputDecoration(
              labelText: 'Jumlah khusus (pilihan)',
              hintText: 'Contoh: 75',
              errorText:
                  controller.customRaisedBedController.text.isNotEmpty &&
                      (int.tryParse(
                                controller.customRaisedBedController.text
                                    .trim(),
                              ) ??
                              0) <=
                          0
                  ? 'Masukkan nombor yang sah.'
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F3F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('Tarikh Tanam'),
          const SizedBox(height: 10),
          AppDateButton(
            key: const Key('open-planted-date-button'),
            label: _formatMalayDate(controller.plantedAt),
            onPressed: onSelectDate,
          ),
          const SizedBox(height: 8),
          FutureBuilder<CropHarvestCatalog>(
            future: CropHarvestCatalog.load(),
            builder: (context, snapshot) => Text(
              snapshot.data?[controller.cropCode]?.plantingDateHelp ??
                  'Tarikh ini digunakan untuk mengira anggaran hasil pertama.',
              key: const Key('harvest-planting-date-help'),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaisedBedSlider extends StatefulWidget {
  const _RaisedBedSlider({required this.controller});

  final ProjectFormController controller;

  @override
  State<_RaisedBedSlider> createState() => _RaisedBedSliderState();
}

class _RaisedBedSliderState extends State<_RaisedBedSlider> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.controller.selectedRaisedBedCount.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${_sliderValue.round()}',
          style: const TextStyle(
            color: AppColors.forest,
            fontSize: 34,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 7,
            activeTrackColor: AppColors.green,
            inactiveTrackColor: const Color(0xFFD8E5DE),
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const _OutlinedSliderThumbShape(),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            key: const Key('raised-bed-slider'),
            padding: const EdgeInsets.symmetric(
              horizontal: _OutlinedSliderThumbShape._radius,
            ),
            min: 1,
            max: 50,
            value: _sliderValue,
            onChanged: (value) {
              setState(() => _sliderValue = value);
            },
            onChangeEnd: (value) {
              final roundedValue = value.round();
              setState(() => _sliderValue = roundedValue.toDouble());
              widget.controller.selectRaisedBedCount(roundedValue);
            },
          ),
        ),
      ],
    );
  }
}

class _OutlinedSliderThumbShape extends SliderComponentShape {
  const _OutlinedSliderThumbShape();

  static const _radius = 15.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.square(_radius * 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center,
      _radius,
      Paint()..color = sliderTheme.thumbColor ?? Colors.white,
    );
    canvas.drawCircle(
      center,
      _radius - 1.5,
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

String _formatMalayDate(DateTime date) {
  const months = <String>[
    'Januari',
    'Februari',
    'Mac',
    'April',
    'Mei',
    'Jun',
    'Julai',
    'Ogos',
    'September',
    'Oktober',
    'November',
    'Disember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
