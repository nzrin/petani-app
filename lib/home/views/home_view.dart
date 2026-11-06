import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:petani/auth/services/auth_service.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/repositories/notification_history_repository.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/controllers/home_controller.dart';
import 'package:petani/home/models/plot_overview.dart';
import 'package:petani/home/navigation/upcoming_task_navigation.dart';
import 'package:petani/home/utils/home_greeting.dart';
import 'package:petani/home/views/upcoming_task_list_view.dart';
import 'package:petani/home/views/task_schedule_view.dart';
import 'package:petani/home/views/notification_history_view.dart';
import 'package:petani/home/widgets/upcoming_task_card.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/shared/widgets/task_empty_state.dart';

const _homeNotificationDotTop = 5.0;
const _homeNotificationDotRight = 5.0;
const _plotCardGradients = <List<Color>>[
  [Color(0xFF064E3B), Color(0xFF0B7A4E)],
  [Color.fromARGB(255, 67, 61, 43), Color.fromARGB(255, 123, 111, 80)],
  [Color.fromARGB(255, 6, 41, 96), Color.fromARGB(255, 11, 70, 166)],
  [Color.fromARGB(255, 129, 49, 3), Color.fromARGB(255, 190, 72, 3)],
  [Color.fromARGB(255, 82, 98, 3), Color.fromARGB(255, 130, 155, 5)],
];

class HomeView extends StatelessWidget {
  const HomeView({
    required this.controller,
    this.onAddPlot,
    this.onAddTask,
    this.taskRepository,
    this.raisedBedRepository,
    this.projectRepository,
    this.notificationHistoryRepository,
    this.authService,
    super.key,
  });

  final HomeController controller;
  final VoidCallback? onAddPlot;
  final VoidCallback? onAddTask;
  final TaskRepository? taskRepository;
  final RaisedBedRepository? raisedBedRepository;
  final ProjectRepository? projectRepository;
  final NotificationHistoryRepository? notificationHistoryRepository;
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    final resolvedNotificationHistoryRepository =
        notificationHistoryRepository ??
        SqliteNotificationHistoryRepository(AppDatabase.instance);
    final resolvedAuthService = authService ?? SupabaseAuthService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([controller, resolvedAuthService]),
      builder: (context, _) => RefreshIndicator(
        onRefresh: controller.loadUpcomingTasks,
        color: AppColors.primaryAction,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            safePadding.top + 18,
            20,
            safePadding.bottom + 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(
                userName: _homeUserName(resolvedAuthService),
                notificationHistoryRepository:
                    resolvedNotificationHistoryRepository,
                onNotificationsTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NotificationHistoryView(
                      repository: resolvedNotificationHistoryRepository,
                      taskRepository: taskRepository,
                      raisedBedRepository: raisedBedRepository,
                    ),
                  ),
                ),
              ),
              if (controller.plotOverviews.isNotEmpty) ...[
                const SizedBox(height: 24),
                _OverviewStack(
                  overviews: controller.plotOverviews,
                  isLoading: controller.isLoading,
                  hasLoadError: controller.hasLoadError,
                  onRetry: controller.loadUpcomingTasks,
                ),
                const SizedBox(height: 26),
              ] else
                const SizedBox(height: 28),
              Text(
                'Tindakan Pantas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      key: const Key('quick-add-plot-button'),
                      imagePath: 'assets/images/farmer_plot_add.png',
                      label: 'TAMBAH PLOT',
                      onTap: onAddPlot,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      key: const Key('task-schedule-button'),
                      imagePath: 'assets/images/farmer_with_pump_sprayer.png',
                      label: 'JADUAL TUGASAN',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TaskScheduleView(
                              repository: controller.repository,
                              taskRepository: taskRepository,
                              raisedBedRepository: raisedBedRepository,
                              projectRepository: projectRepository,
                            ),
                          ),
                        );
                        if (context.mounted) {
                          await controller.loadUpcomingTasks();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      key: const Key('quick-add-task-button'),
                      imagePath: 'assets/images/farmer_task.png',
                      label: 'TAMBAH TUGASAN',
                      onTap: onAddTask,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tugasan Akan Datang',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (controller.tasks.isNotEmpty)
                    TextButton(
                      key: const Key('view-all-upcoming-tasks-button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => UpcomingTaskListView(
                            controller: controller,
                            taskRepository: taskRepository,
                            raisedBedRepository: raisedBedRepository,
                          ),
                        ),
                      ),
                      child: const Text('Lihat Semua'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _UpcomingTaskPreview(
                controller: controller,
                taskRepository: taskRepository,
                raisedBedRepository: raisedBedRepository,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader({
    required this.userName,
    required this.notificationHistoryRepository,
    required this.onNotificationsTap,
  });

  final String userName;
  final NotificationHistoryRepository notificationHistoryRepository;
  final Future<void> Function() onNotificationsTap;

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> with WidgetsBindingObserver {
  Timer? _greetingTimer;
  late String _greeting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshGreeting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshGreeting(notify: true);
  }

  void _refreshGreeting({bool notify = false}) {
    final now = DateTime.now();
    final nextGreeting = homeGreetingFor(now);
    if (notify && nextGreeting != _greeting) {
      setState(() => _greeting = nextGreeting);
    } else {
      _greeting = nextGreeting;
    }

    _greetingTimer?.cancel();
    final nextTransition = _nextGreetingTransition(now);
    _greetingTimer = Timer(
      nextTransition.difference(now) + const Duration(milliseconds: 100),
      () => _refreshGreeting(notify: true),
    );
  }

  DateTime _nextGreetingTransition(DateTime now) {
    for (final hour in const [5, 12, 14, 19]) {
      final transition = DateTime(now.year, now.month, now.day, hour);
      if (transition.isAfter(now)) return transition;
    }
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                key: const Key('home-greeting'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                widget.userName,
                key: const Key('home-user-name'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        _HomeNotificationButton(
          repository: widget.notificationHistoryRepository,
          onTap: widget.onNotificationsTap,
        ),
      ],
    );
  }
}

String _homeUserName(AuthService authService) {
  if (!authService.isAuthenticated) return 'Petani Moden';

  final user = authService.currentUser;
  // The generated account handle is internal; greet social users with the
  // name they already supplied (or a safe fallback), not a long ID suffix.
  if (user?.usernameIsGenerated == true) {
    final displayName = user?.displayName?.trim();
    return displayName?.isNotEmpty == true ? displayName! : 'Petani Moden';
  }
  final candidates = [
    user?.username,
    user?.displayName,
    user?.email?.split('@').first,
  ];
  for (final candidate in candidates) {
    final name = candidate?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return 'Petani Moden';
}

class _HomeNotificationButton extends StatefulWidget {
  const _HomeNotificationButton({
    required this.repository,
    required this.onTap,
  });

  final NotificationHistoryRepository repository;
  final Future<void> Function() onTap;

  @override
  State<_HomeNotificationButton> createState() =>
      _HomeNotificationButtonState();
}

class _HomeNotificationButtonState extends State<_HomeNotificationButton>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _hasUnread = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadUnreadStatus());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_loadUnreadStatus()),
    );
  }

  @override
  void didUpdateWidget(covariant _HomeNotificationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      unawaited(_loadUnreadStatus());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadUnreadStatus());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUnreadStatus() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final hasUnread = await widget.repository.hasUnreadNotifications();
      if (!mounted) return;
      setState(() => _hasUnread = hasUnread);
    } catch (_) {
      // A badge is optional; keep the Home screen usable if storage fails.
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _openNotifications() async {
    await widget.onTap();
    await _loadUnreadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          key: const Key('home-notification-button'),
          onPressed: _openNotifications,
          style: IconButton.styleFrom(backgroundColor: AppColors.green),
          icon: Image.asset(
            'assets/images/icon_speaker.png',
            key: const Key('home-notification-speaker-icon'),
            width: 21,
            height: 21,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
          tooltip: 'Notifikasi',
        ),
        if (_hasUnread)
          const Positioned(
            top: _homeNotificationDotTop,
            right: _homeNotificationDotRight,
            child: SizedBox.square(
              key: Key('home-notification-unread-dot'),
              dimension: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverviewStack extends StatefulWidget {
  const _OverviewStack({
    required this.overviews,
    required this.isLoading,
    required this.hasLoadError,
    required this.onRetry,
  });

  final List<PlotOverview> overviews;
  final bool isLoading;
  final bool hasLoadError;
  final Future<void> Function() onRetry;

  @override
  State<_OverviewStack> createState() => _OverviewStackState();
}

class _OverviewStackState extends State<_OverviewStack>
    with SingleTickerProviderStateMixin {
  static const _cardHeight = 226.0;
  static const _stackHeight = 260.0;
  static const _transitionDuration = Duration(milliseconds: 600);
  static const _autoAdvanceDelay = Duration(seconds: 4);

  late final AnimationController _transitionController;
  late final Animation<double> _transition;
  Timer? _autoAdvanceTimer;
  int _frontIndex = 0;
  bool _isHeld = false;
  bool _resumeTransitionOnRelease = false;
  bool _advanceOnRelease = false;
  DateTime? _autoAdvanceDeadline;
  Duration _remainingAutoAdvanceDelay = _autoAdvanceDelay;
  final Set<String> _precachedImagePaths = {};

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    )..addStatusListener(_handleTransitionStatus);
    _transition = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic,
    );
    _scheduleAutoAdvance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheOverviewImages();
  }

  @override
  void didUpdateWidget(covariant _OverviewStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final plotOrderChanged =
        oldWidget.overviews.length != widget.overviews.length ||
        List.generate(widget.overviews.length, (index) => index).any(
          (index) =>
              oldWidget.overviews[index].plotId !=
              widget.overviews[index].plotId,
        );
    if (plotOrderChanged) {
      _autoAdvanceTimer?.cancel();
      _transitionController.reset();
      _frontIndex = 0;
      _remainingAutoAdvanceDelay = _autoAdvanceDelay;
      _scheduleAutoAdvance();
    }
    _precacheOverviewImages();
  }

  void _precacheOverviewImages() {
    for (final overview in widget.overviews) {
      final imagePath = overview.imagePath;
      if (imagePath.isEmpty || !_precachedImagePaths.add(imagePath)) continue;
      unawaited(precacheImage(AssetImage(imagePath), context));
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _transitionController
      ..removeStatusListener(_handleTransitionStatus)
      ..dispose();
    super.dispose();
  }

  void _scheduleAutoAdvance({Duration? delay}) {
    _autoAdvanceTimer?.cancel();
    if (widget.overviews.length < 2 || _isHeld) return;
    final resolvedDelay = delay ?? _autoAdvanceDelay;
    _remainingAutoAdvanceDelay = resolvedDelay;
    _autoAdvanceDeadline = DateTime.now().add(resolvedDelay);
    _autoAdvanceTimer = Timer(resolvedDelay, () {
      _autoAdvanceDeadline = null;
      _remainingAutoAdvanceDelay = _autoAdvanceDelay;
      _animateToNextCard();
    });
  }

  void _animateToNextCard() {
    if (!mounted ||
        widget.overviews.length < 2 ||
        _isHeld ||
        _transitionController.isAnimating) {
      return;
    }
    _autoAdvanceTimer?.cancel();
    unawaited(_transitionController.forward(from: 0));
  }

  void _handleTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _frontIndex = (_frontIndex + 1) % widget.overviews.length;
      _transitionController.reset();
    });
    _remainingAutoAdvanceDelay = _autoAdvanceDelay;
    _scheduleAutoAdvance();
  }

  void _holdTransition() {
    if (_isHeld) return;
    _isHeld = true;
    final deadline = _autoAdvanceDeadline;
    if (deadline != null) {
      final remaining = deadline.difference(DateTime.now());
      _remainingAutoAdvanceDelay = remaining.isNegative
          ? Duration.zero
          : remaining;
    }
    _autoAdvanceTimer?.cancel();
    _autoAdvanceDeadline = null;
    if (_transitionController.isAnimating) {
      _resumeTransitionOnRelease = true;
      _transitionController.stop(canceled: false);
    }
  }

  void _releaseTransition() {
    if (!_isHeld) return;
    _isHeld = false;
    if (_resumeTransitionOnRelease || _transitionController.value > 0) {
      _resumeTransitionOnRelease = false;
      _advanceOnRelease = false;
      unawaited(_transitionController.forward());
      return;
    }
    if (_advanceOnRelease) {
      _advanceOnRelease = false;
      _animateToNextCard();
      return;
    }
    _scheduleAutoAdvance(delay: _remainingAutoAdvanceDelay);
  }

  void _requestNextCard() {
    if (_transitionController.value > 0) return;
    if (_isHeld) {
      _advanceOnRelease = true;
      return;
    }
    _animateToNextCard();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overviews.isEmpty) {
      return SizedBox(
        key: const Key('farm-overview-empty'),
        height: _cardHeight,
        child: Center(
          child: widget.hasLoadError
              ? TextButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Muat Semula Ringkasan'),
                )
              : widget.isLoading
              ? const CircularProgressIndicator(color: AppColors.primaryAction)
              : Text(
                  'Tiada data tanaman untuk dipaparkan.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
        ),
      );
    }

    if (widget.overviews.length == 1) {
      return SizedBox(
        height: _cardHeight,
        child: _OverviewCard(
          key: ValueKey<String>(
            'plot-overview-${widget.overviews.single.plotId}',
          ),
          overview: widget.overviews.single,
          gradientColors: _plotCardGradients.first,
        ),
      );
    }

    final layerCount = math.min(widget.overviews.length, 5);
    return Listener(
      onPointerDown: (_) => _holdTransition(),
      onPointerUp: (_) => _releaseTransition(),
      onPointerCancel: (_) => _releaseTransition(),
      child: GestureDetector(
        key: const Key('farm-overview-stack'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -180) _requestNextCard();
        },
        child: SizedBox(
          height: _stackHeight,
          child: AnimatedBuilder(
            animation: _transition,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  for (var depth = layerCount - 1; depth >= 0; depth--)
                    _buildCardLayer(depth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardLayer(int depth) {
    final overviewIndex = (_frontIndex + depth) % widget.overviews.length;
    final overview = widget.overviews[overviewIndex];
    final progress = _transition.value;
    final linearProgress = _transitionController.value;
    late final double offsetY;
    late final double horizontalScale;
    late final double verticalScale;
    late final double opacity;
    late final double angle;

    if (depth == 0) {
      final fadeProgress = const Interval(
        0.18,
        1,
        curve: Curves.easeOut,
      ).transform(progress);
      offsetY = _lerp(0, -18, progress);
      horizontalScale = _lerp(1, 0.94, progress);
      verticalScale = _lerp(1, 0.94, progress);
      opacity = _lerp(1, 0, fadeProgress);
      angle = _lerp(0, 0.025, progress);
    } else if (depth == 3) {
      final revealProgress = const Interval(
        0,
        0.4,
        curve: Curves.easeOutCubic,
      ).transform(linearProgress);
      offsetY = _lerp(
        _offsetForDepth(2) + 8,
        _offsetForDepth(2),
        revealProgress,
      );
      horizontalScale = _lerp(
        _horizontalScaleForDepth(2) - 0.04,
        _horizontalScaleForDepth(2),
        revealProgress,
      );
      verticalScale = 1;
      opacity = _opacityForDepth(2) * revealProgress;
      angle = 0;
    } else {
      offsetY = _lerp(
        _offsetForDepth(depth),
        _offsetForDepth(depth - 1),
        progress,
      );
      horizontalScale = _lerp(
        _horizontalScaleForDepth(depth),
        _horizontalScaleForDepth(depth - 1),
        progress,
      );
      verticalScale = 1;
      opacity = _lerp(
        _opacityForDepth(depth),
        _opacityForDepth(depth - 1),
        progress,
      );
      angle = 0;
    }

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: _cardHeight,
      child: IgnorePointer(
        ignoring: depth != 0 || _transitionController.isAnimating,
        child: Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.translate(
            key: ValueKey<String>('plot-overview-layer-${overview.plotId}'),
            offset: Offset(0, offsetY),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                alignment: Alignment.topCenter,
                scaleX: horizontalScale,
                scaleY: verticalScale,
                child: _OverviewCard(
                  key: ValueKey<String>(
                    'plot-overview-card-${overview.plotId}',
                  ),
                  overview: overview,
                  gradientColors:
                      _plotCardGradients[overviewIndex %
                          _plotCardGradients.length],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _offsetForDepth(int depth) {
    if (depth <= 0) return 0;
    return 18 + ((depth - 1) * 16);
  }

  double _horizontalScaleForDepth(int depth) => 1 - (depth * 0.08);

  double _opacityForDepth(int depth) {
    if (depth >= 3) return 0;
    return 1 - (depth * 0.08);
  }

  double _lerp(double begin, double end, double progress) {
    return begin + ((end - begin) * progress);
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.overview,
    required this.gradientColors,
    super.key,
  });

  final PlotOverview overview;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final daysToHarvest = overview.daysToHarvest;

    return Container(
      key: ValueKey<String>('plot-overview-background-${overview.plotId}'),
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -30,
            width: 180,
            height: 180,
            child: Opacity(
              opacity: 0.92,
              child: Image.asset(overview.imagePath, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 90, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    overview.projectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  overview.plotName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${overview.cropName} · ${overview.totalPlants} pokok direkod',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD8E9E0),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  daysToHarvest == null ? '— hari' : '$daysToHarvest hari',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        overview.harvestLabel,
                        style: const TextStyle(
                          color: Color(0xFFD8E9E0),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // The stack's pointer listener pauses both its timer and
                    // active transition until this press is released/cancelled.
                    Tooltip(
                      message: overview.harvestExplanation,
                      triggerMode: TooltipTriggerMode.longPress,
                      showDuration: Duration.zero,
                      child: SizedBox.square(
                        key: ValueKey<String>(
                          'harvest-info-${overview.plotId}',
                        ),
                        dimension: 28,
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFFD8E9E0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.imagePath,
    required this.label,
    this.onTap,
    super.key,
  });

  final String imagePath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 92,
              width: double.infinity,
              child: Image.asset(
                imagePath,
                key: ValueKey<String>('quick-action-image-$label'),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: Center(
                child: Text(
                  label.replaceFirst(' ', '\n'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
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

class _UpcomingTaskPreview extends StatelessWidget {
  const _UpcomingTaskPreview({
    required this.controller,
    this.taskRepository,
    this.raisedBedRepository,
  });

  final HomeController controller;
  final TaskRepository? taskRepository;
  final RaisedBedRepository? raisedBedRepository;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAction),
        ),
      );
    }
    if (controller.hasLoadError && controller.tasks.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: controller.loadUpcomingTasks,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Cuba Lagi'),
        ),
      );
    }
    if (controller.tasks.isEmpty) {
      return const SizedBox(
        key: Key('empty-upcoming-tasks'),
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Center(
            child: TaskEmptyState(
              topSpacing: 5,
              description: 'Tugasan akan datang akan dipaparkan di sini.',
              illustrationKey: Key('empty-upcoming-task-tractor'),
            ),
          ),
        ),
      );
    }
    final tasks = controller.previewTasks;
    return Column(
      key: const Key('home-upcoming-task-group'),
      children: [
        for (var index = 0; index < tasks.length; index++)
          UpcomingTaskCard(
            task: tasks[index],
            isFirstInGroup: index == 0,
            isLastInGroup: index == tasks.length - 1,
            onTap: () => openUpcomingTaskDetail(
              context: context,
              task: tasks[index],
              taskRepository: taskRepository,
              raisedBedRepository: raisedBedRepository,
              onChanged: controller.loadUpcomingTasks,
            ),
          ),
      ],
    );
  }
}
