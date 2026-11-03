import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/chatbot/views/chatbot_view.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/controllers/home_controller.dart';
import 'package:petani/home/navigation/upcoming_task_navigation.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/home/views/home_view.dart';
import 'package:petani/main/controllers/main_controller.dart';
import 'package:petani/main/widgets/liquid_glass_navigation_bar.dart';
import 'package:petani/profile/models/app_icon_option.dart';
import 'package:petani/profile/services/app_icon_service.dart';
import 'package:petani/profile/views/profile_view.dart';
import 'package:petani/project/controllers/project_controller.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/control_product.dart';
import 'package:petani/project/models/task_control_product.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/project_form_sheet.dart';
import 'package:petani/project/views/project_detail_view.dart';
import 'package:petani/project/views/project_view.dart';
import 'package:petani/project/views/fertilizer_list_view.dart';
import 'package:petani/project/views/fungicide_list_view.dart';
import 'package:petani/project/views/herbicide_list_view.dart';
import 'package:petani/project/views/insecticide_list_view.dart';
import 'package:petani/project/views/plot_detail_view.dart';
import 'package:petani/project/views/task_form_sheet.dart';
import 'package:petani/project/views/task_target_picker_sheet.dart';
import 'package:petani/report/controllers/report_controller.dart';
import 'package:petani/report/repositories/report_repository.dart';
import 'package:petani/report/views/report_view.dart';
import 'package:petani/shared/controllers/crop_selection_controller.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:petani/shared/repositories/crop_selection_repository.dart';
import 'package:petani/shared/widgets/crop_selection_sheet.dart';
import 'package:petani/sync/controllers/sync_coordinator.dart';

class MainView extends StatefulWidget {
  const MainView({
    required this.initialCrop,
    super.key,
    this.cropSelectionRepository,
    this.projectRepository,
    this.homeRepository,
    this.taskRepository,
    this.raisedBedRepository,
    this.appIconService,
    this.authService,
    this.onLogout,
    this.showProjectFormOnStart = false,
  });

  final String initialCrop;
  final CropSelectionRepository? cropSelectionRepository;
  final ProjectRepository? projectRepository;
  final HomeRepository? homeRepository;
  final TaskRepository? taskRepository;
  final RaisedBedRepository? raisedBedRepository;
  final AppIconService? appIconService;
  final AuthService? authService;
  final VoidCallback? onLogout;
  final bool showProjectFormOnStart;

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  late final MainController _controller;
  late final List<Widget> _pages;
  late final ProjectRepository _projectRepository;
  late final ProjectController _projectController;
  late final HomeController _homeController;
  late final ReportController _reportController;
  late final TaskRepository _taskRepository;
  late final RaisedBedRepository _raisedBedRepository;
  late final AppIconService _appIconService;
  AppIconOption _selectedAppIcon = AppIconOption.options.first;

  @override
  void initState() {
    super.initState();
    _controller = MainController();
    _controller.addListener(_handleDestinationChanged);
    SyncCoordinator.instance.addListener(_handleCloudDataChanged);
    _appIconService = widget.appIconService ?? const AppIconService();
    _projectRepository =
        widget.projectRepository ??
        SqliteProjectRepository(AppDatabase.instance);
    _taskRepository = widget.taskRepository ?? createDefaultTaskRepository();
    _raisedBedRepository =
        widget.raisedBedRepository ??
        SqliteRaisedBedRepository(AppDatabase.instance);
    _projectController = ProjectController(_projectRepository);
    _homeController = HomeController(
      repository:
          widget.homeRepository ?? SqliteHomeRepository(AppDatabase.instance),
    );
    _reportController = ReportController(
      repository: SqliteReportRepository(AppDatabase.instance),
    );
    _pages = [
      HomeView(
        controller: _homeController,
        authService: widget.authService,
        onAddPlot: _openQuickAddPlot,
        onAddTask: _openQuickAddTask,
        projectRepository: _projectRepository,
        taskRepository: _taskRepository,
        raisedBedRepository: _raisedBedRepository,
      ),
      ProjectView(
        controller: _projectController,
        raisedBedRepository: _raisedBedRepository,
        taskRepository: _taskRepository,
        onPlotDataChanged: _homeController.loadUpcomingTasks,
      ),
      ReportView(controller: _reportController),
      ProfileView(
        authService: widget.authService,
        onLogout: widget.onLogout,
        appIconService: _appIconService,
        onAppIconChanged: _handleAppIconChanged,
      ),
    ];
    unawaited(_loadSelectedAppIcon());
    unawaited(_homeController.loadUpcomingTasks());
    unawaited(_projectController.loadProjects());

    if (widget.showProjectFormOnStart) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openProjectForm(cropCode: _initialCropCode),
      );
    }
  }

  void _handleDestinationChanged() {
    if (_controller.currentIndex == 0) {
      unawaited(_homeController.loadUpcomingTasks());
    }
    if (_controller.currentIndex == 2) unawaited(_reportController.load());
  }

  void _handleCloudDataChanged() {
    unawaited(_homeController.loadUpcomingTasks());
    unawaited(_projectController.loadProjects());
    unawaited(_reportController.load());
  }

  Future<void> _loadSelectedAppIcon() async {
    final nativeName = await _appIconService.getCurrentIcon();
    if (!mounted) return;
    setState(() => _selectedAppIcon = AppIconOption.fromNativeName(nativeName));
  }

  void _handleAppIconChanged(AppIconOption icon) {
    if (!mounted || icon.nativeName == _selectedAppIcon.nativeName) return;
    setState(() => _selectedAppIcon = icon);
  }

  Future<void> _openCropSelection() async {
    final controller = CropSelectionController();
    final selectedCrop = await showModalBottomSheet<CropOption>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CropSelectionSheet(controller: controller),
    );
    controller.dispose();

    if (!mounted || selectedCrop == null) return;
    await _openProjectForm(cropCode: selectedCrop.code);
  }

  String get _initialCropCode => CropSelectionController.cropOptions
      .firstWhere(
        (crop) =>
            crop.name == widget.initialCrop || crop.code == widget.initialCrop,
        orElse: () => CropSelectionController.cropOptions.first,
      )
      .code;

  Future<void> _openQuickAddPlot() {
    return _openProjectForm(
      cropCode: _initialCropCode,
      requireExistingProject: true,
    );
  }

  Future<void> _openQuickAddTask() async {
    List<ProjectRecord> projects;
    try {
      projects = await _projectRepository.getProjects();
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Senarai projek tidak dapat dimuatkan. Cuba lagi.',
        isError: true,
      );
      return;
    }
    if (!mounted) return;
    if (projects.isEmpty) {
      AppToast.show(
        context,
        'Tambah sebuah projek sebelum menambah tugasan.',
        isError: true,
      );
      return;
    }

    final plot = await showTaskTargetPickerSheet(
      context: context,
      projects: projects,
    );
    if (!mounted || plot == null) return;

    try {
      final raisedBeds = await _raisedBedRepository.getRaisedBeds(plot.id);
      if (!mounted) return;
      final result = await showTaskFormSheet(
        context: context,
        plotId: plot.id,
        cropCode: plot.cropCode,
        raisedBeds: raisedBeds,
      );
      if (!mounted || result?.action != TaskFormSheetAction.save) return;
      await _taskRepository.createTask(result!.data!);
      await _homeController.loadUpcomingTasks();
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Tugasan tidak dapat disimpan. Cuba lagi.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    AppToast.show(context, 'Tugasan berjaya ditambah.');
  }

  Future<void> _openChatbot() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatbotView(
          onAddTask: _openQuickAddTask,
          onLoadIncompleteTasks: _loadIncompleteChatbotTasks,
          onCompleteTask: _completeChatbotTask,
          onSetTaskControlMethod: _setChatbotTaskControlMethod,
          onOpenTaskDetail: _openChatbotTaskDetail,
          onAddPlot: _openQuickAddPlot,
          onAddProject: _openCropSelection,
          onLoadProjects: _loadChatbotProjects,
          onOpenProjectDetail: _openChatbotProjectDetail,
          onLoadPlots: _loadChatbotPlots,
          onOpenPlotDetail: _openChatbotPlotDetail,
        ),
      ),
    );
  }

  Future<List<ChatbotTaskItem>> _loadIncompleteChatbotTasks() async {
    final results = await Future.wait<dynamic>([
      _homeController.repository.getUpcomingTasks(fromDate: DateTime(1900)),
      _taskRepository.getAllTasks(),
    ]);
    final upcomingTasks = results[0] as List<UpcomingTaskRecord>;
    final taskDetails = results[1] as List<PlotTaskRecord>;
    final detailsById = <int, PlotTaskRecord>{
      for (final task in taskDetails) task.id: task,
    };

    return upcomingTasks
        .map((task) {
          final detail = detailsById[task.id];
          final canComplete =
              detail != null &&
              (!detail.type.supportsControlMethod ||
                  detail.controlMethod != null);
          return ChatbotTaskItem(
            id: task.id,
            plotId: task.plotId,
            title: task.title,
            projectName: task.projectName,
            plotName: task.plotName,
            contextLabel: task.contextLabel,
            scheduledAt: task.scheduledAt,
            imagePath: task.type.imagePath,
            canComplete: canComplete,
          );
        })
        .toList(growable: false);
  }

  Future<List<ChatbotProjectItem>> _loadChatbotProjects() async {
    final projects = await _projectRepository.getProjects();
    return projects
        .map((project) {
          var imagePath = '';
          for (final plot in project.plots) {
            if (plot.imagePath.isNotEmpty) {
              imagePath = plot.imagePath;
              break;
            }
          }
          return ChatbotProjectItem(
            key: project.key,
            name: project.projectName,
            location: project.location,
            cropNames: project.cropTypes
                .map((crop) => crop.name)
                .toList(growable: false),
            plotCount: project.plots.length,
            imagePath: imagePath,
          );
        })
        .toList(growable: false);
  }

  Future<List<ChatbotPlotItem>> _loadChatbotPlots() async {
    final projects = await _projectRepository.getProjects();
    return [
      for (final project in projects)
        for (final plot in project.plots)
          ChatbotPlotItem(
            id: plot.id,
            projectKey: project.key,
            projectName: project.projectName,
            name: plot.name,
            cropName: plot.cropName,
            rowSummary: CropRowTerminology.forCropCode(
              plot.cropCode,
            ).count(plot.raisedBedCount),
            imagePath: plot.imagePath,
          ),
    ];
  }

  Future<void> _openChatbotProjectDetail(ChatbotProjectItem item) async {
    final projects = await _projectRepository.getProjects();
    ProjectRecord? selectedProject;
    for (final project in projects) {
      if (project.key == item.key) {
        selectedProject = project;
        break;
      }
    }
    if (selectedProject == null) {
      throw StateError('Project ${item.key} is no longer available.');
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectDetailView(
          project: selectedProject!,
          projectController: _projectController,
          raisedBedRepository: _raisedBedRepository,
          taskRepository: _taskRepository,
          onPlotDataChanged: _homeController.loadUpcomingTasks,
        ),
      ),
    );
    await Future.wait<void>([
      _projectController.loadProjects(),
      _homeController.loadUpcomingTasks(),
    ]);
  }

  Future<void> _openChatbotPlotDetail(ChatbotPlotItem item) async {
    final projects = await _projectRepository.getProjects();
    ProjectRecord? selectedProject;
    PlotRecord? selectedPlot;
    for (final project in projects) {
      if (project.key != item.projectKey) continue;
      for (final plot in project.plots) {
        if (plot.id == item.id) {
          selectedProject = project;
          selectedPlot = plot;
          break;
        }
      }
      if (selectedPlot != null) break;
    }
    if (selectedProject == null || selectedPlot == null) {
      throw StateError('Plot ${item.id} is no longer available.');
    }
    if (!mounted) return;

    await Navigator.of(context).push<PlotDeletionResult>(
      MaterialPageRoute<PlotDeletionResult>(
        builder: (_) => PlotDetailView(
          plot: selectedPlot!,
          project: selectedProject!,
          projectController: _projectController,
          repository: _raisedBedRepository,
          taskRepository: _taskRepository,
          onPlotDataChanged: _homeController.loadUpcomingTasks,
        ),
      ),
    );
    await Future.wait<void>([
      _projectController.loadProjects(),
      _homeController.loadUpcomingTasks(),
    ]);
  }

  Future<void> _completeChatbotTask(ChatbotTaskItem task) async {
    await _taskRepository.markTaskCompleted(
      taskId: task.id,
      plotId: task.plotId,
    );
    await Future.wait<void>([
      _homeController.loadUpcomingTasks(),
      _reportController.load(),
    ]);
  }

  Future<bool> _setChatbotTaskControlMethod(
    ChatbotTaskItem task,
    ChatbotControlMethod method,
  ) async {
    final repositoryMethod = switch (method) {
      ChatbotControlMethod.organic => TaskControlMethod.organic,
      ChatbotControlMethod.chemical => TaskControlMethod.chemical,
    };
    var products = const <TaskControlProduct>[];

    if (method == ChatbotControlMethod.chemical) {
      final tasks = await _taskRepository.getTasks(task.plotId);
      PlotTaskRecord? selectedTask;
      for (final candidate in tasks) {
        if (candidate.id == task.id) {
          selectedTask = candidate;
          break;
        }
      }
      if (selectedTask == null) {
        throw StateError('Task ${task.id} is no longer available.');
      }
      if (!mounted) return false;
      final selectedProducts = await _openChatbotControlProductList(
        selectedTask,
      );
      if (!mounted || selectedProducts == null) return false;
      products = selectedProducts
          .map(
            (product) => TaskControlProduct(
              name: product.name,
              detail: product.primaryDetail,
            ),
          )
          .toList(growable: false);
    }

    await _taskRepository.updateControlMethod(
      taskId: task.id,
      plotId: task.plotId,
      method: repositoryMethod,
      products: products,
    );
    return true;
  }

  Future<List<ControlProduct>?> _openChatbotControlProductList(
    PlotTaskRecord task,
  ) {
    final page = switch (task.type) {
      FarmTaskType.fungusControl => const FungicideListView(),
      FarmTaskType.insectControl => const InsecticideListView(),
      FarmTaskType.weedControl => const HerbicideListView(),
      FarmTaskType.fertilizing => const FertilizerListView(),
      _ => null,
    };
    if (page == null) return Future.value(null);
    return Navigator.of(context).push<List<ControlProduct>>(
      MaterialPageRoute<List<ControlProduct>>(builder: (_) => page),
    );
  }

  Future<void> _openChatbotTaskDetail(ChatbotTaskItem task) {
    return openTaskDetailByReference(
      context: context,
      taskId: task.id,
      plotId: task.plotId,
      projectName: task.projectName,
      plotName: task.plotName,
      taskRepository: _taskRepository,
      raisedBedRepository: _raisedBedRepository,
      onChanged: () async {
        await Future.wait<void>([
          _homeController.loadUpcomingTasks(),
          _reportController.load(),
        ]);
      },
    );
  }

  Future<void> _openProjectForm({
    String cropCode = 'pineapple',
    bool requireExistingProject = false,
  }) async {
    ProjectFormSuggestions suggestions;
    try {
      suggestions = await _projectRepository.getFormSuggestions();
    } catch (_) {
      suggestions = const ProjectFormSuggestions();
    }
    if (!mounted) return;
    if (requireExistingProject && suggestions.existingProjects.isEmpty) {
      AppToast.show(
        context,
        'Tambah sebuah projek sebelum menambah plot.',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<ProjectFormData>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectFormSheet(
        cropCode: cropCode,
        suggestions: suggestions,
        requireExistingProject: requireExistingProject,
      ),
    );

    if (!mounted || result == null) return;

    try {
      await _projectRepository.createProject(result);
      await _projectController.loadProjects();
      await _homeController.loadUpcomingTasks();
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Projek tidak dapat disimpan. Cuba lagi.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    AppToast.show(
      context,
      requireExistingProject
          ? 'Plot berjaya ditambah.'
          : 'Projek berjaya ditambah.',
    );
  }

  @override
  void dispose() {
    SyncCoordinator.instance.removeListener(_handleCloudDataChanged);
    _controller.removeListener(_handleDestinationChanged);
    _controller.dispose();
    _homeController.dispose();
    _projectController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: _controller.currentIndex,
              children: List.generate(_pages.length, (index) {
                return TickerMode(
                  enabled: index == _controller.currentIndex,
                  child: _pages[index],
                );
              }),
            ),
            bottomNavigationBar: LiquidGlassNavigationBar(
              selectedIndex: _controller.currentIndex,
              onDestinationSelected: _controller.selectDestination,
              destinations: _controller.destinations,
              profileAvatarAssetPath: _selectedAppIcon.assetPath,
            ),
            floatingActionButton: switch (_controller.currentIndex) {
              0 => KeyedSubtree(
                key: const Key('main-floating-action-button-slot'),
                child: FloatingActionButton(
                  key: const Key('chatbot-floating-button'),
                  heroTag: 'chatbot-floating-button',
                  onPressed: _openChatbot,
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  tooltip: 'Buka Sahabat Petani',
                  child: const _PulsingAssistantIcon(),
                ),
              ),
              1 => KeyedSubtree(
                key: const Key('main-floating-action-button-slot'),
                child: FloatingActionButton(
                  key: const Key('add-project-button'),
                  heroTag: 'add-project-floating-button',
                  onPressed: _openCropSelection,
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  tooltip: 'Tambah projek',
                  child: const Icon(Icons.add_rounded),
                ),
              ),
              _ => null,
            },
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        );
      },
    );
  }
}

class _PulsingAssistantIcon extends StatefulWidget {
  const _PulsingAssistantIcon();

  @override
  State<_PulsingAssistantIcon> createState() => _PulsingAssistantIconState();
}

class _PulsingAssistantIconState extends State<_PulsingAssistantIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _scale = Tween<double>(begin: 0.92, end: 1.06).animate(curved);
    _opacity = Tween<double>(begin: 0.86, end: 1).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/images/icon_head_1000.png',
            key: const Key('chatbot-floating-icon'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
