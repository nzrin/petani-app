import 'package:petani/project/models/crop_variety_catalog.dart';
import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/shared/widgets/empty_state_illustration.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/controllers/plot_detail_controller.dart';
import 'package:petani/project/controllers/project_controller.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/seedling_count_sheet.dart';
import 'package:petani/project/views/task_detail_view.dart';
import 'package:petani/project/views/task_form_sheet.dart';
import 'package:petani/shared/formatters/malay_date_time_formatter.dart';
import 'package:petani/project/views/project_form_sheet.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';
import 'package:petani/shared/widgets/app_button.dart';

class PlotDeletionResult {
  const PlotDeletionResult(this.project);

  final ProjectRecord? project;
}

class PlotDetailView extends StatefulWidget {
  const PlotDetailView({
    required this.plot,
    required this.project,
    required this.projectController,
    super.key,
    this.repository,
    this.taskRepository,
    this.onProjectChanged,
    this.onPlotDataChanged,
  });

  final PlotRecord plot;
  final ProjectRecord project;
  final ProjectController projectController;
  final RaisedBedRepository? repository;
  final TaskRepository? taskRepository;
  final ValueChanged<ProjectRecord>? onProjectChanged;
  final Future<void> Function()? onPlotDataChanged;

  @override
  State<PlotDetailView> createState() => _PlotDetailViewState();
}

class _PlotDetailViewState extends State<PlotDetailView>
    with SingleTickerProviderStateMixin {
  late final PlotDetailController _controller;
  late final TabController _tabController;
  late ProjectRecord _project;
  late PlotRecord _plot;
  late DateTime _selectedTaskMonth;
  int? _selectedBedNumber;
  bool _plotDeletedDuringEdit = false;
  ProjectRecord? _projectAfterDeletion;

  CropRowTerminology get _rowTerminology =>
      CropRowTerminology.forCropCode(_plot.cropCode);

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _plot = widget.plot;
    _selectedTaskMonth = _monthStart(DateTime.now());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _controller = PlotDetailController(
      plot: widget.plot,
      repository:
          widget.repository ?? SqliteRaisedBedRepository(AppDatabase.instance),
      taskRepository: widget.taskRepository ?? createDefaultTaskRepository(),
    );
    _controller.initialize();
  }

  void _handleTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editRaisedBed(RaisedBedRecord initialRaisedBed) async {
    var raisedBed = initialRaisedBed;
    while (mounted) {
      setState(() => _selectedBedNumber = raisedBed.bedNumber);
      final result = await showSeedlingCountSheet(
        context: context,
        cropCode: _plot.cropCode,
        bedNumber: raisedBed.bedNumber,
        initialCount: raisedBed.seedlingCount,
        availableVarieties: _plot.varieties,
        initialVarieties: raisedBed.varieties,
      );
      if (!mounted) return;
      setState(() => _selectedBedNumber = null);
      if (result == null) return;

      final saved = await _controller.saveRaisedBedDetails(
        raisedBed: raisedBed,
        seedlingCount: result.seedlingCount,
        varieties: result.varieties,
      );
      if (!mounted) return;
      if (!saved) {
        _showSaveError();
        return;
      }
      await widget.onPlotDataChanged?.call();
      if (!mounted) return;
      if (!result.saveAndContinue) return;

      final currentIndex = _controller.raisedBeds.indexWhere(
        (item) => item.bedNumber == raisedBed.bedNumber,
      );
      if (currentIndex < 0 ||
          currentIndex == _controller.raisedBeds.length - 1) {
        return;
      }
      raisedBed = _controller.raisedBeds[currentIndex + 1];
    }
  }

  Future<void> _editInBulk() async {
    final result = await showSeedlingCountSheet(
      context: context,
      cropCode: _plot.cropCode,
      initialCount: null,
      isBulk: true,
      availableVarieties: _plot.varieties,
    );
    if (!mounted || result == null) return;

    final saved = await _controller.saveBulkRaisedBedDetails(
      seedlingCount: result.seedlingCount,
      onlyUnset: result.onlyUnset,
      varieties: result.varieties,
    );
    if (!mounted) return;
    if (!saved) {
      _showSaveError();
      return;
    }
    await widget.onPlotDataChanged?.call();
  }

  void _showSaveError() {
    AppToast.show(
      context,
      'Maklumat ${_rowTerminology.lowercase} tidak dapat disimpan.',
      isError: true,
    );
  }

  Future<bool> _deletePlot() async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      imagePath: 'assets/images/trash.png',
      title: 'Padam plot?',
      description:
          'Semua ${_rowTerminology.lowercase} dan tugasan dalam ${_plot.name} '
          'akan dipadam. '
          'Tindakan ini tidak boleh dibatalkan.',
      confirmLabel: 'Ya, Padam',
      confirmColor: const Color(0xFFE53935),
    );
    if (!confirmed || !mounted) return false;

    try {
      final updatedProject = await widget.projectController.deletePlot(
        project: _project,
        plotId: _plot.id,
      );
      if (!mounted) return false;
      _plotDeletedDuringEdit = true;
      _projectAfterDeletion = updatedProject;
      return true;
    } on Exception {
      if (!mounted) return false;
      AppToast.show(
        context,
        'Plot tidak dapat dipadam. Cuba lagi.',
        isError: true,
      );
      return false;
    }
  }

  Future<void> _editPlot() async {
    _plotDeletedDuringEdit = false;
    _projectAfterDeletion = null;
    ProjectFormSuggestions suggestions;
    try {
      suggestions = await widget.projectController.getFormSuggestions();
    } on Exception {
      suggestions = const ProjectFormSuggestions();
    }
    if (!mounted) return;

    final fixedProject = ExistingProjectSuggestion(
      name: _project.projectName,
      location: _project.location,
      plotNames: _project.plots
          .map((plot) => plot.name)
          .toList(growable: false),
    );
    final initialData = ProjectFormData(
      cropCode: _plot.cropCode,
      projectName: _project.projectName,
      location: _project.location,
      plotName: _plot.name,
      varieties: _plot.varieties,
      raisedBedCount: _plot.raisedBedCount,
      plantedAt: _plot.plantedAt ?? DateTime.now(),
    );
    final result = await showModalBottomSheet<ProjectFormData>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectFormSheet(
        cropCode: _plot.cropCode,
        suggestions: suggestions,
        fixedProject: fixedProject,
        initialData: initialData,
        onDelete: _deletePlot,
      ),
    );
    if (!mounted) return;
    if (_plotDeletedDuringEdit) {
      Navigator.of(context).pop(PlotDeletionResult(_projectAfterDeletion));
      return;
    }
    if (result == null) return;

    if (result.raisedBedCount < _plot.raisedBedCount) {
      final confirmed = await showAppConfirmationSheet(
        context: context,
        imagePath: 'assets/images/trash.png',
        title: 'Kurangkan jumlah ${_rowTerminology.lowercase}?',
        description:
            '${_rowTerminology.title} selepas nombor '
            '${result.raisedBedCount} serta maklumat '
            'anak pokok dan varieti yang direkodkan akan dipadam.',
        confirmLabel: 'Ya, Teruskan',
        confirmColor: const Color(0xFFE53935),
      );
      if (!confirmed || !mounted) return;
    }

    try {
      final updatedProject = await widget.projectController.updatePlot(
        plotId: _plot.id,
        data: result,
      );
      if (updatedProject == null) throw StateError('Project reload failed.');
      if (!mounted) return;
      final updatedPlot = updatedProject.plots.firstWhere(
        (plot) => plot.id == _plot.id,
      );
      setState(() {
        _project = updatedProject;
        _plot = updatedPlot;
      });
      widget.onProjectChanged?.call(updatedProject);
      await Future.wait([
        _controller.loadRaisedBeds(),
        _controller.loadTasks(),
      ]);
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Maklumat plot tidak dapat disimpan. Cuba lagi.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    AppToast.show(context, 'Maklumat plot berjaya dikemas kini.');
  }

  Future<void> _openTaskForm() async {
    final result = await showTaskFormSheet(
      context: context,
      plotId: _plot.id,
      cropCode: _plot.cropCode,
      raisedBeds: _controller.raisedBeds,
    );
    if (!mounted || result?.action != TaskFormSheetAction.save) return;
    final taskData = result!.data!;

    final saved = await _controller.createTask(taskData);
    if (!mounted) return;
    if (saved) {
      setState(() {
        _selectedTaskMonth = _monthStart(taskData.scheduledAt);
      });
    }
    AppToast.show(
      context,
      saved
          ? 'Tugasan berjaya ditambah.'
          : 'Tugasan tidak dapat disimpan. Cuba lagi.',
      isError: !saved,
    );
  }

  void _openTaskDetail(PlotTaskRecord task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailView(
          task: task,
          projectName: _project.projectName,
          plotName: _plot.name,
          totalRaisedBeds: _plot.raisedBedCount,
          raisedBeds: _controller.raisedBeds,
          repository: _controller.taskRepository,
          onTaskChanged: _controller.replaceTask,
          onTaskDeleted: _controller.removeTask,
        ),
      ),
    );
  }

  Future<void> _pickTaskMonth() async {
    final month = await showModalBottomSheet<DateTime>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KeyboardInsetPadding(
        child: _MonthYearPickerSheet(initialMonth: _selectedTaskMonth),
      ),
    );
    if (!mounted || month == null) return;
    setState(() => _selectedTaskMonth = _monthStart(month));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.navigationTitle.copyWith(
            color: Colors.white,
          ),
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemStatusBarContrastEnforced: false,
          ),
          title: Text(_plot.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton(
              key: const Key('edit-plot-button'),
              onPressed: _editPlot,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                'Ubah',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                key: const Key('plot-detail-tab-bar'),
                controller: _tabController,
                tabs: [
                  const Tab(text: 'Tugasan'),
                  Tab(text: _rowTerminology.title),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFBFD8CC),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                indicatorColor: const Color(0xFFFDD24E),
                indicatorWeight: 3,
                dividerColor: const Color(0xFF4C896B),
              ),
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return TabBarView(
              controller: _tabController,
              children: [_buildTaskTab(), _buildRaisedBedTab()],
            );
          },
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_tabController.index != 0 || _controller.tasks.isEmpty) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton(
              key: const Key('add-task-floating-button'),
              onPressed: _controller.isTaskSaving ? null : _openTaskForm,
              backgroundColor: AppColors.primaryAction,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              tooltip: 'Tambah tugasan',
              child: _controller.isTaskSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskTab() {
    if (_controller.isTaskLoading && _controller.tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _buildPlotHeader(context),
          const SizedBox(height: 100),
          const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAction),
          ),
        ],
      );
    }

    if (_controller.hasTaskLoadError && _controller.tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _buildPlotHeader(context),
          const SizedBox(height: 80),
          const Text(
            'Tugasan tidak dapat dimuatkan.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _controller.loadTasks,
              child: const Text('Cuba Lagi'),
            ),
          ),
        ],
      );
    }

    if (_controller.tasks.isNotEmpty) return _buildTaskGrid();

    return ListView(
      key: const PageStorageKey<String>('plot-task-tab'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _buildPlotHeader(context),
        const SizedBox(height: 54),
        Center(
          child: EmptyStateIllustration(key: const Key('empty-task-tractor')),
        ),
        Text(
          'Tiada Tugasan',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Tugasan untuk plot ini akan dipaparkan di sini.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 190,
            child: AppButton(
              height: 45,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              key: const Key('add-task-button'),
              label: 'Tambah Tugasan',
              onPressed: _controller.isLoading ? null : _openTaskForm,
              disabledBackgroundColor: const Color(0xFFCCD4CF),
              disabledForegroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskGrid() {
    final selectedMonthTaskCount = _tasksForSelectedMonth.length;
    final hasTasksForSelectedMonth = selectedMonthTaskCount > 0;
    return CustomScrollView(
      key: const PageStorageKey<String>('plot-task-tab'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildPlotHeader(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Senarai Tugasan',
                            style: TextStyle(
                              color: AppColors.forest,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$selectedMonthTaskCount tugasan',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      key: const Key('task-month-selector'),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE0E6E3)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _pickTaskMonth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatCompactTaskMonth(_selectedTaskMonth),
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.ink,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasTasksForSelectedMonth) ...[
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      SizedBox(
                        width: 41,
                        child: Text(
                          'TARIKH',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      SizedBox(width: 32),
                      Expanded(
                        child: Text(
                          'TUGASAN',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasTasksForSelectedMonth)
          SliverLayoutBuilder(
            builder: (context, constraints) {
              return SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.remainingPaintExtent,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 100,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Stack(
                          children: [
                            const Positioned(
                              top: 0,
                              bottom: 0,
                              left: 56,
                              child: SizedBox(
                                key: Key('task-timeline-line'),
                                width: 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x00D6DEDA),
                                        Color(0xFFD6DEDA),
                                        Color(0xFFD6DEDA),
                                        Color(0x00D6DEDA),
                                      ],
                                      stops: [0, 0.12, 0.88, 1],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              key: const Key('task-grid'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildTaskDateGroups(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptySelectedMonth(),
          ),
      ],
    );
  }

  List<PlotTaskRecord> get _tasksForSelectedMonth => _controller.tasks
      .where((task) => _monthStart(task.scheduledAt) == _selectedTaskMonth)
      .toList(growable: false);

  Widget _buildEmptySelectedMonth() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.paddingOf(context).bottom + 100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyStateIllustration(key: const Key('empty-month-task-tractor')),
          Text(
            'Tiada Tugasan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tiada tugasan untuk bulan ini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskDateGroups() {
    final groups = <DateTime, List<PlotTaskRecord>>{};
    for (final task in _controller.tasks) {
      final date = DateTime(
        task.scheduledAt.year,
        task.scheduledAt.month,
        task.scheduledAt.day,
      );
      if (_monthStart(date) == _selectedTaskMonth) {
        groups.putIfAbsent(date, () => []).add(task);
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_monthStart(today) == _selectedTaskMonth) {
      groups.putIfAbsent(today, () => []);
    }

    final entries = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 42),
          child: Center(
            child: Text(
              'Tiada tugasan untuk bulan ini.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      ];
    }

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return _TaskTimelineRow(
        key: ValueKey<String>('task-date-group-${entry.key.toIso8601String()}'),
        date: entry.key,
        isToday: entry.key == today,
        children: entry.value.isEmpty
            ? const [_NoTaskTodayCard()]
            : entry.value
                  .map((task) {
                    return _TaskCard(
                      task: task,
                      cropCode: _plot.cropCode,
                      totalRaisedBeds: _plot.raisedBedCount,
                      onTap: () => _openTaskDetail(task),
                    );
                  })
                  .toList(growable: false),
      );
    });
  }

  Widget _buildRaisedBedTab() {
    return CustomScrollView(
      key: const PageStorageKey<String>('raised-bed-map-tab'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildPlotHeader(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSummary()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Senarai ${_rowTerminology.title}',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const Key('bulk-seedling-count-button'),
                  onPressed: _controller.isSaving ? null : _editInBulk,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: const Text('Isi Pukal'),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          sliver: SliverToBoxAdapter(child: _buildFilters()),
        ),
        ..._buildRaisedBedContent(),
      ],
    );
  }

  Widget _buildPlotHeader(BuildContext context) {
    return Container(
      key: const Key('plot-crop-summary-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: _plot.imagePath.isEmpty
                ? const Icon(
                    Icons.grass_rounded,
                    color: AppColors.green,
                    size: 30,
                  )
                : Image.asset(_plot.imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _plot.cropName,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                if (_plot.varieties.isEmpty)
                  Text(
                    '${CropVarietyCatalog.fieldTitle(_plot.cropCode)} belum ditetapkan',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Text.rich(
                    TextSpan(
                      children: [
                        for (
                          var index = 0;
                          index < _plot.varieties.length;
                          index++
                        ) ...[
                          TextSpan(text: _plot.varieties[index].label),
                          if (index != _plot.varieties.length - 1)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                child: Container(
                                  key: ValueKey<String>(
                                    'plot-variety-dot-$index',
                                  ),
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.muted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                value: '${_plot.raisedBedCount}',
                label: _rowTerminology.title,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                value: '${_controller.configuredCount}/${_plot.raisedBedCount}',
                label: 'Diisi',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                value: _formatNumber(_controller.totalSeedlings),
                label: 'Pokok',
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          _controller.configuredCount == 0
              ? 'Purata akan dipaparkan selepas '
                    '${_rowTerminology.lowercase} pertama diisi.'
              : 'Purata ${_formatNumber(_controller.averageSeedlings)} anak pokok '
                    'bagi setiap ${_rowTerminology.lowercase} yang telah diisi.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Semua',
            selected: _controller.filter == RaisedBedFilter.all,
            onSelected: () => _controller.selectFilter(RaisedBedFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Belum Diisi',
            selected: _controller.filter == RaisedBedFilter.unset,
            onSelected: () => _controller.selectFilter(RaisedBedFilter.unset),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sudah Diisi',
            selected: _controller.filter == RaisedBedFilter.configured,
            onSelected: () =>
                _controller.selectFilter(RaisedBedFilter.configured),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRaisedBedContent() {
    if (_controller.isLoading && _controller.raisedBeds.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        ),
      ];
    }
    if (_controller.hasLoadError && _controller.raisedBeds.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TextButton(
              onPressed: _controller.loadRaisedBeds,
              child: const Text('Cuba Lagi'),
            ),
          ),
        ),
      ];
    }

    final raisedBeds = _controller.visibleRaisedBeds;
    if (raisedBeds.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 100),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Tiada ${_rowTerminology.lowercase} untuk penapis ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.paddingOf(context).bottom + 28,
        ),
        sliver: SliverGrid(
          key: const Key('raised-bed-grid'),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.6,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final raisedBed = raisedBeds[index];
            return _RaisedBedCell(
              raisedBed: raisedBed,
              terminology: _rowTerminology,
              isSelected: _selectedBedNumber == raisedBed.bedNumber,
              onTap: _controller.isSaving
                  ? null
                  : () => _editRaisedBed(raisedBed),
            );
          }, childCount: raisedBeds.length),
        ),
      ),
    ];
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.cropCode,
    required this.totalRaisedBeds,
    required this.onTap,
  });

  final PlotTaskRecord task;
  final String cropCode;
  final int totalRaisedBeds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<int>(task.id),
      color: task.isCompleted ? const Color(0xFF088A4F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: task.isCompleted
            ? BorderSide.none
            : const BorderSide(color: Color(0xFFE0E6E3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                11,
                task.isCompleted ? 54 : 12,
                11,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset(
                      task.type.imagePath,
                      key: ValueKey<String>(
                        'task-list-image-${task.type.code}',
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.type.labelForCrop(cropCode),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: task.isCompleted
                                ? Colors.white
                                : AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _TaskMeta(
                          icon: Icons.schedule_rounded,
                          label: formatMalayTime(task.scheduledAt),
                          color: task.isCompleted
                              ? Colors.white70
                              : AppColors.muted,
                        ),
                        const SizedBox(height: 3),
                        _TaskMeta(
                          icon: Icons.grid_view_rounded,
                          label: task.raisedBedSummary(
                            totalRaisedBeds,
                            forCropCode: cropCode,
                          ),
                          color: task.isCompleted
                              ? Colors.white70
                              : AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (task.isCompleted)
              Positioned(
                top: 0,
                right: 12,
                bottom: 0,
                width: 30,
                child: Center(
                  child: SizedBox.square(
                    key: const Key('completed-task-icon'),
                    dimension: 30,
                    child: Image.asset(
                      'assets/images/completed.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTimelineRow extends StatelessWidget {
  const _TaskTimelineRow({
    required this.date,
    required this.isToday,
    required this.children,
    super.key,
  });

  final DateTime date;
  final bool isToday;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: const Key('task-date-column'),
            width: 41,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    date.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: isToday ? AppColors.primaryAction : AppColors.ink,
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _weekdayMalay(date),
                    style: TextStyle(
                      color: isToday
                          ? AppColors.primaryAction
                          : AppColors.muted,
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  key: isToday ? const Key('current-date-dot') : null,
                  top: 15,
                  left: isToday ? 7 : 10,
                  child: Container(
                    width: isToday ? 18 : 12,
                    height: isToday ? 18 : 12,
                    padding: EdgeInsets.all(isToday ? 4 : 2.5),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.mint : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday
                            ? const Color(0xFFB8E4C8)
                            : const Color(0xFF9AA69F),
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primaryAction
                            : const Color(0xFF9AA69F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _visibleYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _visibleYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('month-year-picker-sheet'),
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DBD9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Pilih Bulan',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    key: const Key('previous-year-button'),
                    onPressed: () => setState(() => _visibleYear--),
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.primaryAction,
                  ),
                  Expanded(
                    child: Text(
                      '$_visibleYear',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('next-year-button'),
                    onPressed: () => setState(() => _visibleYear++),
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.primaryAction,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                key: const Key('month-picker-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shortMalayMonths.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final selected = month == _selectedMonth;
                  return InkWell(
                    key: ValueKey<String>('month-option-$month'),
                    onTap: () => setState(() => _selectedMonth = month),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.mint
                            : const Color(0xFFF7F8F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryAction
                              : const Color(0xFFE0E6E3),
                        ),
                      ),
                      child: Text(
                        _shortMalayMonths[index],
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryAction
                              : AppColors.muted,
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('cancel-month-picker-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.primaryAction,
                        side: const BorderSide(color: AppColors.primaryAction),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      key: const Key('confirm-month-picker-button'),
                      label: 'Pilih',
                      height: 48,
                      fontSize: 15,
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(DateTime(_visibleYear, _selectedMonth)),
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

class _NoTaskTodayCard extends StatelessWidget {
  const _NoTaskTodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6E3)),
      ),
      child: const Text(
        'Tiada tugasan hari ini.',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.icon,
    required this.label,
    this.color = AppColors.muted,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.mint,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.green : const Color(0xFFDDE3E0),
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.forest : AppColors.muted,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: const StadiumBorder(),
    );
  }
}

class _RaisedBedCell extends StatelessWidget {
  const _RaisedBedCell({
    required this.raisedBed,
    required this.terminology,
    required this.isSelected,
    required this.onTap,
  });

  final RaisedBedRecord raisedBed;
  final CropRowTerminology terminology;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final configured = raisedBed.isConfigured;
    return Semantics(
      button: true,
      label: configured
          ? '${terminology.title} ${raisedBed.bedNumber}, '
                '${raisedBed.seedlingCount} anak pokok'
          : '${terminology.title} ${raisedBed.bedNumber}, belum diisi',
      child: InkWell(
        key: ValueKey<String>('raised-bed-${raisedBed.bedNumber}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Text(
              '${terminology.abbreviation}'
              '${raisedBed.bedNumber.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: configured
                        ? AppColors.creamDark
                        : const Color(0xFFF1F3F2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: configured
                          ? AppColors.creamDeep
                          : isSelected
                          ? const Color(0xFF987E2F)
                          : const Color(0xFFD6DEDA),
                      width: isSelected ? 4 : 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    configured ? '${raisedBed.seedlingCount}' : '0',
                    maxLines: 1,
                    style: TextStyle(
                      color: configured ? AppColors.creamDeep : AppColors.green,
                      fontSize: configured ? 14 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              raisedBed.varietyGridLabel,
              key: ValueKey<String>(
                'raised-bed-variety-label-${raisedBed.bedNumber}',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: raisedBed.varieties.isEmpty
                    ? const Color(0xFFADB6B1)
                    : AppColors.forest,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);

const _shortMalayMonths = <String>[
  'Jan',
  'Feb',
  'Mac',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Ogo',
  'Sep',
  'Okt',
  'Nov',
  'Dis',
];

String _formatCompactTaskMonth(DateTime value) =>
    '${_shortMalayMonths[value.month - 1]}, ${value.year}';

String _weekdayMalay(DateTime value) {
  const weekdays = <String>['ISN', 'SEL', 'RAB', 'KHA', 'JUM', 'SAB', 'AHD'];
  return weekdays[value.weekday - 1];
}

String _formatNumber(int value) {
  final digits = '$value';
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
