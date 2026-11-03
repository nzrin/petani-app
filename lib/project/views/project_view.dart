import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:petani/shared/widgets/isometric_tractor.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/controllers/project_controller.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/project_detail_view.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';

class ProjectView extends StatelessWidget {
  const ProjectView({
    required this.controller,
    super.key,
    this.raisedBedRepository,
    this.taskRepository,
    this.onPlotDataChanged,
  });

  final ProjectController controller;
  final RaisedBedRepository? raisedBedRepository;
  final TaskRepository? taskRepository;
  final Future<void> Function()? onPlotDataChanged;

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, safePadding.top + 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projek',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pantau semua plot tanaman yang telah anda daftarkan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading && controller.projects.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
              )
            else if (controller.hasLoadError && controller.projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadErrorState(onRetry: controller.loadProjects),
              )
            else if (controller.projects.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyProjectState(),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  safePadding.bottom + 120,
                ),
                sliver: SliverList.separated(
                  itemCount: controller.projects.length,
                  itemBuilder: (context, index) {
                    final project = controller.projects[index];
                    return _ProjectSummaryCard(
                      key: ValueKey<String>(project.key),
                      project: project,
                      projectController: controller,
                      raisedBedRepository: raisedBedRepository,
                      taskRepository: taskRepository,
                      onPlotDataChanged: onPlotDataChanged,
                      isDeleting: controller.isDeleting(project),
                      onDelete: () => _confirmDelete(context, project),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProjectRecord project,
  ) async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      imagePath: 'assets/images/trash.png',
      title: 'Padam projek?',
      description:
          'Semua plot dalam ${project.projectName} akan dipadam. '
          'Tindakan ini tidak boleh dibatalkan.',
      confirmLabel: 'Ya, Padam',
      confirmColor: const Color(0xFFFF584F),
    );
    if (!confirmed || !context.mounted) return;

    final deleted = await controller.deleteProject(project);
    if (!context.mounted || deleted) return;
    AppToast.show(
      context,
      'Projek tidak dapat dipadam. Cuba lagi.',
      isError: true,
    );
  }
}

class _ProjectSummaryCard extends StatelessWidget {
  const _ProjectSummaryCard({
    required this.project,
    required this.projectController,
    required this.raisedBedRepository,
    required this.taskRepository,
    required this.onPlotDataChanged,
    required this.isDeleting,
    required this.onDelete,
    super.key,
  });

  final ProjectRecord project;
  final ProjectController projectController;
  final RaisedBedRepository? raisedBedRepository;
  final TaskRepository? taskRepository;
  final Future<void> Function()? onPlotDataChanged;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProjectDetailView(
                project: project,
                projectController: projectController,
                raisedBedRepository: raisedBedRepository,
                taskRepository: taskRepository,
                onPlotDataChanged: onPlotDataChanged,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            key: ValueKey<String>('project-card-content-${project.key}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      key: ValueKey<String>(
                        'project-card-summary-${project.key}',
                      ),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.projectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (project.location.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/icon_location.png',
                                key: ValueKey<String>(
                                  'project-card-location-icon-${project.key}',
                                ),
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  project.location,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          key: ValueKey<String>(
                            'project-card-crop-pills-${project.key}',
                          ),
                          spacing: 7,
                          runSpacing: 7,
                          children: project.cropTypes
                              .map((crop) => _CropTypePill(label: crop.name))
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    key: ValueKey<String>('delete-project-${project.key}'),
                    onPressed: isDeleting ? null : onDelete,
                    tooltip: 'Padam projek',
                    color: const Color(0xFFB3261E),
                    icon: isDeleting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.asset(
                            'assets/images/icon_delete.png',
                            width: 27,
                            height: 27,
                            fit: BoxFit.contain,
                          ),
                  ),
                ],
              ),
              if (project.plots.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ProjectPlotScroller(
                  projectKey: project.key,
                  plots: project.plots,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectPlotScroller extends StatefulWidget {
  const _ProjectPlotScroller({required this.projectKey, required this.plots});

  final String projectKey;
  final List<PlotRecord> plots;

  @override
  State<_ProjectPlotScroller> createState() => _ProjectPlotScrollerState();
}

class _ProjectPlotScrollerState extends State<_ProjectPlotScroller> {
  late final ScrollController _scrollController;
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_updateFades);
    _scheduleFadeUpdate();
  }

  @override
  void didUpdateWidget(covariant _ProjectPlotScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plots != widget.plots) _scheduleFadeUpdate();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateFades)
      ..dispose();
    super.dispose();
  }

  void _scheduleFadeUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFades();
    });
  }

  void _updateFades() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final position = _scrollController.position;
    final showLeftFade = position.extentBefore > 0.5;
    final showRightFade = position.extentAfter > 0.5;
    if (showLeftFade == _showLeftFade && showRightFade == _showRightFade) {
      return;
    }
    setState(() {
      _showLeftFade = showLeftFade;
      _showRightFade = showRightFade;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        children: [
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              _scheduleFadeUpdate();
              return false;
            },
            child: ListView.separated(
              key: ValueKey<String>('project-plot-scroll-${widget.projectKey}'),
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.plots.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _ProjectPlotPreviewCard(plot: widget.plots[index]);
              },
            ),
          ),
          if (_showLeftFade)
            _HorizontalScrollFade(
              key: ValueKey<String>(
                'project-plot-left-fade-${widget.projectKey}',
              ),
              alignment: Alignment.centerLeft,
            ),
          if (_showRightFade)
            _HorizontalScrollFade(
              key: ValueKey<String>(
                'project-plot-right-fade-${widget.projectKey}',
              ),
              alignment: Alignment.centerRight,
            ),
        ],
      ),
    );
  }
}

class _ProjectPlotPreviewCard extends StatelessWidget {
  const _ProjectPlotPreviewCard({required this.plot});

  final PlotRecord plot;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('project-plot-preview-${plot.id}'),
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E5)),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 38,
            child: plot.imagePath.isEmpty
                ? const Icon(
                    Icons.grass_rounded,
                    color: AppColors.green,
                    size: 22,
                  )
                : Image.asset(plot.imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  CropRowTerminology.forCropCode(
                    plot.cropCode,
                  ).count(plot.raisedBedCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalScrollFade extends StatelessWidget {
  const _HorizontalScrollFade({required this.alignment, super.key});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      width: 28,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [Colors.white, Colors.white.withValues(alpha: 0)],
            ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.forest,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IsometricTractor(key: const Key('empty-project-tractor')),
          Text(
            'Tiada Projek',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan butang + untuk menambah projek tanaman pertama anda.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.muted,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            'Senarai projek tidak dapat dimuatkan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: const Text('Cuba Lagi')),
        ],
      ),
    );
  }
}
