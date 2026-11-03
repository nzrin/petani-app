import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/controllers/project_controller.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/plot_detail_view.dart';
import 'package:petani/project/views/project_edit_sheet.dart';
import 'package:petani/project/views/project_form_sheet.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/widgets/crop_selection_sheet.dart';

class ProjectDetailView extends StatefulWidget {
  const ProjectDetailView({
    required this.project,
    super.key,
    this.projectController,
    this.raisedBedRepository,
    this.taskRepository,
    this.onPlotDataChanged,
  });

  final ProjectRecord project;
  final ProjectController? projectController;
  final RaisedBedRepository? raisedBedRepository;
  final TaskRepository? taskRepository;
  final Future<void> Function()? onPlotDataChanged;

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  late final ProjectController _projectController;
  late final bool _ownsProjectController;
  late ProjectRecord _project;
  bool _isUpdatingProject = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _ownsProjectController = widget.projectController == null;
    _projectController =
        widget.projectController ??
        ProjectController(SqliteProjectRepository(AppDatabase.instance));
  }

  @override
  void dispose() {
    if (_ownsProjectController) _projectController.dispose();
    super.dispose();
  }

  ExistingProjectSuggestion _fixedProjectSuggestion(
    ProjectFormSuggestions suggestions,
  ) {
    final normalizedName = _project.projectName.trim().toLowerCase();
    for (final project in suggestions.existingProjects) {
      if (project.name.trim().toLowerCase() == normalizedName) return project;
    }
    return ExistingProjectSuggestion(
      name: _project.projectName,
      location: _project.location,
      plotNames: _project.plots
          .map((plot) => plot.name)
          .toList(growable: false),
    );
  }

  Future<void> _addPlot() async {
    final cropController = CropSelectionController();
    final crop = await showModalBottomSheet<CropOption>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CropSelectionSheet(controller: cropController),
    );
    cropController.dispose();
    if (!mounted || crop == null) return;

    ProjectFormSuggestions suggestions;
    try {
      suggestions = await _projectController.getFormSuggestions();
    } on Exception {
      suggestions = const ProjectFormSuggestions();
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<ProjectFormData>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectFormSheet(
        cropCode: crop.code,
        suggestions: suggestions,
        fixedProject: _fixedProjectSuggestion(suggestions),
      ),
    );
    if (!mounted || result == null) return;

    try {
      final updatedProject = await _projectController.createPlot(result);
      if (updatedProject == null) throw StateError('Project reload failed.');
      if (mounted) setState(() => _project = updatedProject);
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Plot tidak dapat disimpan. Cuba lagi.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    AppToast.show(context, 'Plot berjaya ditambah.');
  }

  Future<void> _editProject() async {
    final result = await showProjectEditSheet(
      context: context,
      projectName: _project.projectName,
      location: _project.location,
    );
    if (!mounted || result == null) return;

    setState(() => _isUpdatingProject = true);
    try {
      final updatedProject = await _projectController.updateProject(
        project: _project,
        projectName: result.projectName,
        location: result.location,
      );
      if (updatedProject == null) {
        throw StateError('Project reload failed.');
      }
      if (!mounted) return;
      setState(() => _project = updatedProject);
      AppToast.show(context, 'Maklumat projek berjaya dikemas kini.');
    } on ProjectNameConflictException {
      if (!mounted) return;
      AppToast.show(context, 'Nama projek ini sudah digunakan.', isError: true);
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Maklumat projek tidak dapat disimpan. Cuba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUpdatingProject = false);
    }
  }

  void _handleProjectChanged(ProjectRecord? project) {
    if (!mounted) return;
    if (project == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _project = project);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          key: const Key('add-plot-button'),
          onPressed: _addPlot,
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          tooltip: 'Tambah plot',
          child: const Icon(Icons.add_rounded),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              backgroundColor: AppColors.cream,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: AppTypography.navigationTitle.copyWith(
                color: AppColors.ink,
              ),
              title: Text(
                _project.projectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                TextButton(
                  key: const Key('edit-project-button'),
                  onPressed: _isUpdatingProject ? null : _editProject,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.green,
                    disabledForegroundColor: AppColors.muted,
                  ),
                  child: const Text(
                    'Ubah',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_project.location.isNotEmpty) ...[
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/icon_location.png',
                            key: const Key('project-detail-location-icon'),
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _project.location,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      key: const Key('project-detail-crop-pills'),
                      spacing: 7,
                      runSpacing: 7,
                      children: _project.cropTypes
                          .map((crop) => _CropTypePill(label: crop.name))
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Senarai Plot',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.paddingOf(context).bottom + 104,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 255,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _PlotCard(
                    plot: _project.plots[index],
                    project: _project,
                    projectController: _projectController,
                    raisedBedRepository: widget.raisedBedRepository,
                    taskRepository: widget.taskRepository,
                    onPlotDataChanged: widget.onPlotDataChanged,
                    onProjectChanged: _handleProjectChanged,
                  );
                }, childCount: _project.plots.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlotCard extends StatelessWidget {
  const _PlotCard({
    required this.plot,
    required this.project,
    required this.projectController,
    required this.raisedBedRepository,
    required this.taskRepository,
    required this.onPlotDataChanged,
    required this.onProjectChanged,
  });

  final PlotRecord plot;
  final ProjectRecord project;
  final ProjectController projectController;
  final RaisedBedRepository? raisedBedRepository;
  final TaskRepository? taskRepository;
  final Future<void> Function()? onPlotDataChanged;
  final ValueChanged<ProjectRecord?> onProjectChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<int>(plot.id),
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final deletionResult = await Navigator.of(context).push(
            MaterialPageRoute<PlotDeletionResult>(
              builder: (_) => PlotDetailView(
                plot: plot,
                project: project,
                projectController: projectController,
                repository: raisedBedRepository,
                taskRepository: taskRepository,
                onPlotDataChanged: onPlotDataChanged,
                onProjectChanged: onProjectChanged,
              ),
            ),
          );
          if (!context.mounted || deletionResult == null) return;
          onProjectChanged(deletionResult.project);
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: plot.imagePath.isEmpty
                    ? const Icon(
                        Icons.grass_rounded,
                        color: AppColors.green,
                        size: 22,
                      )
                    : Image.asset(plot.imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(height: 9),
              _CropTypePill(label: plot.cropName),
              const SizedBox(height: 14),
              Text(
                plot.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                CropRowTerminology.forCropCode(
                  plot.cropCode,
                ).count(plot.raisedBedCount),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (plot.varietyLabel.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  plot.varietyLabel,
                  key: ValueKey<String>(
                    'project-detail-plot-varieties-${plot.id}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const Spacer(),
              if (plot.plantedAt case final plantedAt?)
                Row(
                  key: ValueKey<String>('project-detail-plot-date-${plot.id}'),
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatShortDate(plantedAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropTypePill extends StatelessWidget {
  const _CropTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.forest,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatShortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
