import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

const _taskTargetCellHeight = 80.0;

Future<PlotRecord?> showTaskTargetPickerSheet({
  required BuildContext context,
  required List<ProjectRecord> projects,
}) {
  return showModalBottomSheet<PlotRecord>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskTargetPickerSheet(projects: projects),
  );
}

class TaskTargetPickerSheet extends StatefulWidget {
  const TaskTargetPickerSheet({required this.projects, super.key});

  final List<ProjectRecord> projects;

  @override
  State<TaskTargetPickerSheet> createState() => _TaskTargetPickerSheetState();
}

class _TaskTargetPickerSheetState extends State<TaskTargetPickerSheet> {
  int _currentStep = 0;
  ProjectRecord? _selectedProject;
  PlotRecord? _selectedPlot;

  bool get _canContinue =>
      _currentStep == 0 ? _selectedProject != null : _selectedPlot != null;

  void _handleLeadingAction() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _currentStep = 0;
      _selectedPlot = null;
    });
  }

  void _continue() {
    if (!_canContinue) return;
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }
    Navigator.pop(context, _selectedPlot);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return KeyboardInsetPadding(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            key: const Key('task-target-picker-sheet'),
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                        key: const Key('task-target-leading-button'),
                        onPressed: _handleLeadingAction,
                        icon: Icon(
                          _currentStep == 0
                              ? Icons.close_rounded
                              : Icons.arrow_back_rounded,
                        ),
                        color: AppColors.ink,
                        tooltip: _currentStep == 0 ? 'Tutup' : 'Kembali',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(
                      2,
                      (index) => Expanded(
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
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _currentStep == 0
                        ? _ProjectSelectionStep(
                            key: const ValueKey<String>('project-step'),
                            projects: widget.projects,
                            selectedProject: _selectedProject,
                            onSelected: (project) {
                              setState(() {
                                _selectedProject = project;
                                _selectedPlot = null;
                              });
                            },
                          )
                        : _PlotSelectionStep(
                            key: const ValueKey<String>('plot-step'),
                            project: _selectedProject!,
                            selectedPlot: _selectedPlot,
                            onSelected: (plot) {
                              setState(() => _selectedPlot = plot);
                            },
                          ),
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AppButton(
                    key: const Key('task-target-continue-button'),
                    label: 'Seterusnya',
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
    );
  }
}

class _ProjectSelectionStep extends StatelessWidget {
  const _ProjectSelectionStep({
    required this.projects,
    required this.selectedProject,
    required this.onSelected,
    super.key,
  });

  final List<ProjectRecord> projects;
  final ProjectRecord? selectedProject;
  final ValueChanged<ProjectRecord> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SelectionStep(
      title: 'Pilih Projek',
      description: 'Pilih projek untuk tugasan yang ingin ditambah.',
      children: [
        for (final project in projects)
          _SelectionCard(
            key: ValueKey<String>('task-target-project-${project.key}'),
            icon: Icons.folder_outlined,
            title: project.projectName,
            secondaryText: '${project.plots.length} plot',
            selected: selectedProject?.key == project.key,
            onTap: () => onSelected(project),
          ),
      ],
    );
  }
}

class _PlotSelectionStep extends StatelessWidget {
  const _PlotSelectionStep({
    required this.project,
    required this.selectedPlot,
    required this.onSelected,
    super.key,
  });

  final ProjectRecord project;
  final PlotRecord? selectedPlot;
  final ValueChanged<PlotRecord> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SelectionStep(
      title: 'Pilih Plot',
      description: 'Pilih plot dalam ${project.projectName}.',
      children: [
        for (final plot in project.plots)
          _SelectionCard(
            key: ValueKey<String>('task-target-plot-${plot.id}'),
            imagePath: _seedImagePath(plot.cropCode),
            title: plot.name,
            secondaryText: plot.cropName,
            tertiaryText: CropRowTerminology.forCropCode(
              plot.cropCode,
            ).count(plot.raisedBedCount),
            secondaryAsPill: true,
            selected: selectedPlot?.id == plot.id,
            onTap: () => onSelected(plot),
          ),
      ],
    );
  }
}

class _SelectionStep extends StatelessWidget {
  const _SelectionStep({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          GridView.count(
            key: const Key('task-target-selection-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: _taskTargetCellHeight,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.secondaryText,
    required this.selected,
    required this.onTap,
    this.icon,
    this.imagePath,
    this.tertiaryText,
    this.secondaryAsPill = false,
    super.key,
  });

  final String title;
  final String secondaryText;
  final String? tertiaryText;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? imagePath;
  final bool secondaryAsPill;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : const Color(0xFFF7F8F7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primaryAction
                  : const Color(0xFFDDE3E0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (imagePath == null)
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryAction, size: 23),
                )
              else
                SizedBox.square(
                  dimension: 42,
                  child: Image.asset(imagePath!, fit: BoxFit.contain),
                ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (secondaryAsPill)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    if (tertiaryText case final tertiaryText?) ...[
                      const SizedBox(height: 4),
                      Text(
                        tertiaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppColors.primaryAction
                    : const Color(0xFFABB5B0),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _seedImagePath(String cropCode) => switch (cropCode) {
  'coconut' => 'assets/images/seeds/coconut_fruit.png',
  'banana' => 'assets/images/seeds/banana_fruit.png',
  'oil_palm' => 'assets/images/seeds/oil_palm_fruit_bunch.png',
  'rubber_tree' => 'assets/images/seeds/rubber_seeds.png',
  'ginger' => 'assets/images/seeds/ginger_rhizome.png',
  'rice' => 'assets/images/seeds/rice_stalks.png',
  'torch_ginger' => 'assets/images/seeds/torch_ginger_buds.png',
  'corn' => 'assets/images/seeds/corn.png',
  'cassava' => 'assets/images/seeds/cassava.png',
  'sweet_potato' => 'assets/images/seeds/sweet_potato.png',
  'durian' => 'assets/images/seeds/durian.png',
  'watermelon' => 'assets/images/seeds/watermelon.png',
  'rock_melon' => 'assets/images/seeds/rock_melon.png',
  'strawberry' => 'assets/images/seeds/strawberry.png',
  'chilli' => 'assets/images/seeds/chilli.png',
  'cucumber' => 'assets/images/seeds/cucumber.png',
  'eggplant' => 'assets/images/seeds/eggplant.png',
  'lime' => 'assets/images/seeds/lime.png',
  'pandan' => 'assets/images/seeds/pandan.png',
  'lemongrass' => 'assets/images/seeds/lemongrass.png',
  'tomato' => 'assets/images/seeds/tomato.png',
  'turmeric' => 'assets/images/seeds/turmeric.png',
  'calamansi' => 'assets/images/seeds/calamansi.png',
  'kesum' => 'assets/images/seeds/kesum.png',
  _ => 'assets/images/seeds/pineapple_fruit.png',
};
