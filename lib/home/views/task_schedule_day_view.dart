import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/models/task_schedule_record.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/task_detail_view.dart';
import 'package:petani/project/views/task_form_sheet.dart';
import 'package:petani/project/views/task_target_picker_sheet.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/task_empty_state.dart';

const _timeColumnWidth = 31.0;
const _timelineGutterWidth = 32.0;

class TaskScheduleDayView extends StatefulWidget {
  const TaskScheduleDayView({
    required this.date,
    required this.repository,
    this.taskRepository,
    this.raisedBedRepository,
    this.projectRepository,
    this.onScheduleChanged,
    super.key,
  });

  final DateTime date;
  final HomeRepository repository;
  final TaskRepository? taskRepository;
  final RaisedBedRepository? raisedBedRepository;
  final ProjectRepository? projectRepository;
  final Future<void> Function()? onScheduleChanged;

  @override
  State<TaskScheduleDayView> createState() => _TaskScheduleDayViewState();
}

class _TaskScheduleDayViewState extends State<TaskScheduleDayView> {
  late final TaskRepository _taskRepository;
  late final RaisedBedRepository _raisedBedRepository;
  late final ProjectRepository _projectRepository;
  List<TaskScheduleRecord> _tasks = const [];
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isOpeningTask = false;
  bool _isAddingTask = false;

  @override
  void initState() {
    super.initState();
    _taskRepository = widget.taskRepository ?? createDefaultTaskRepository();
    _projectRepository =
        widget.projectRepository ??
        SqliteProjectRepository(AppDatabase.instance);
    _raisedBedRepository =
        widget.raisedBedRepository ??
        SqliteRaisedBedRepository(AppDatabase.instance);
    _loadTasks();
  }

  Future<void> _addTask() async {
    if (_isAddingTask || _isOpeningTask) return;
    setState(() => _isAddingTask = true);
    try {
      final projects = await _projectRepository.getProjects();
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
      final raisedBeds = await _raisedBedRepository.getRaisedBeds(plot.id);
      if (!mounted) return;
      final result = await showTaskFormSheet(
        context: context,
        plotId: plot.id,
        cropCode: plot.cropCode,
        raisedBeds: raisedBeds,
        initialDate: DateUtils.dateOnly(widget.date),
      );
      if (!mounted || result?.action != TaskFormSheetAction.save) return;
      await _taskRepository.createTask(result!.data!);
      if (!mounted) return;
      AppToast.show(context, 'Tugasan berjaya ditambah.');
      await _refreshSchedule();
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Tugasan tidak dapat ditambah. Cuba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isAddingTask = false);
    }
  }

  Future<void> _openTask(TaskScheduleRecord scheduledTask) async {
    if (_isOpeningTask || _isAddingTask) return;
    setState(() => _isOpeningTask = true);
    try {
      final results = await Future.wait<Object>([
        _taskRepository.getTasks(scheduledTask.plotId),
        _raisedBedRepository.getRaisedBeds(scheduledTask.plotId),
      ]);
      final tasks = results[0] as List<PlotTaskRecord>;
      final raisedBeds = results[1] as List<RaisedBedRecord>;
      final task = tasks.firstWhere((item) => item.id == scheduledTask.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailView(
            task: task,
            projectName: scheduledTask.projectName,
            plotName: scheduledTask.plotName,
            totalRaisedBeds: raisedBeds.length,
            raisedBeds: raisedBeds,
            repository: _taskRepository,
            onTaskChanged: _handleTaskChanged,
            onTaskDeleted: _handleTaskDeleted,
          ),
        ),
      );
      if (mounted) await _loadTasks();
    } on Exception {
      if (!mounted) return;
      AppToast.show(
        context,
        'Butiran tugasan tidak dapat dibuka. Cuba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isOpeningTask = false);
    }
  }

  void _handleTaskChanged(PlotTaskRecord _) {
    unawaited(_refreshSchedule());
  }

  void _handleTaskDeleted(int _) {
    unawaited(_refreshSchedule());
  }

  Future<void> _refreshSchedule() async {
    final refreshes = <Future<void>>[_loadTasks()];
    final onScheduleChanged = widget.onScheduleChanged;
    if (onScheduleChanged != null) refreshes.add(onScheduleChanged());
    await Future.wait(refreshes);
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    try {
      final monthlyTasks = await widget.repository.getScheduledTasksForMonth(
        widget.date,
      );
      final tasks =
          monthlyTasks
              .where(
                (task) => DateUtils.isSameDay(task.scheduledAt, widget.date),
              )
              .toList(growable: false)
            ..sort(
              (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
            );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
      });
    }
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
          title: Text(_formatFullDate(widget.date)),
          centerTitle: true,
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.navigationTitle.copyWith(
            color: Colors.white,
          ),
        ),
        body: Column(
          children: [
            if (!_isLoading && !_hasLoadError && _tasks.isNotEmpty)
              const _TaskColumnHeaders(),
            Expanded(child: _buildContent()),
          ],
        ),
        floatingActionButton: _tasks.isEmpty
            ? null
            : FloatingActionButton(
                key: const Key('add-schedule-day-task-floating-button'),
                onPressed: _isAddingTask || _isOpeningTask ? null : _addTask,
                backgroundColor: AppColors.primaryAction,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                tooltip: 'Tambah tugasan',
                child: _isAddingTask
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
              ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAction),
      );
    }
    if (_hasLoadError) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadTasks,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Cuba Lagi'),
        ),
      );
    }
    if (_tasks.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TaskEmptyState(
                title: 'Tiada Tugasan',
                description: 'Tiada tugasan dijadualkan pada tarikh ini.',
                illustrationKey: Key('empty-task-schedule-day-tractor'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 190,
                child: AppButton(
                  key: const Key('add-schedule-day-task-button'),
                  label: 'Tambah Tugasan',
                  height: 45,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  onPressed: _isAddingTask || _isOpeningTask ? null : _addTask,
                  disabledBackgroundColor: const Color(0xFFCCD4CF),
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      color: AppColors.primaryAction,
      child: ListView(
        key: const Key('task-schedule-day-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.paddingOf(context).bottom + 88,
        ),
        children: [
          Stack(
            children: [
              const Positioned(
                top: 0,
                bottom: 0,
                left: 46,
                child: SizedBox(
                  key: Key('task-schedule-timeline-line'),
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
                children: [
                  for (var index = 0; index < _tasks.length; index++)
                    _TaskTimeTimelineRow(
                      task: _tasks[index],
                      showTime:
                          index == 0 ||
                          !_hasSameTime(_tasks[index - 1], _tasks[index]),
                      child: _TaskCard(
                        task: _tasks[index],
                        onTap: _isOpeningTask || _isAddingTask
                            ? null
                            : () => _openTask(_tasks[index]),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskColumnHeaders extends StatelessWidget {
  const _TaskColumnHeaders();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          SizedBox(
            width: _timeColumnWidth,
            child: Text(
              'MASA',
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
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final TaskScheduleRecord task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = task.isCompleted ? Colors.white : AppColors.ink;
    final metadataColor = task.isCompleted ? Colors.white70 : AppColors.muted;
    return Material(
      key: ValueKey<String>('task-schedule-day-task-${task.id}'),
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
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _TaskMeta(
                          icon: Icons.grid_view_rounded,
                          label: task.contextLabel,
                          color: metadataColor,
                        ),
                        if (task.location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          _TaskMeta(
                            icon: Icons.location_on_outlined,
                            label: task.location,
                            color: metadataColor,
                          ),
                        ],
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

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _TaskTimeTimelineRow extends StatelessWidget {
  const _TaskTimeTimelineRow({
    required this.task,
    required this.showTime,
    required this.child,
  });

  final TaskScheduleRecord task;
  final bool showTime;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: ValueKey<String>('task-schedule-time-${task.id}'),
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showTime) ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatClock(task.scheduledAt),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _malayPeriod(task.scheduledAt).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: _timelineGutterWidth,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  key: ValueKey<String>('task-schedule-time-dot-${task.id}'),
                  top: 15,
                  left: task.isCompleted ? 7 : 10,
                  child: Container(
                    width: task.isCompleted ? 18 : 12,
                    height: task.isCompleted ? 18 : 12,
                    padding: EdgeInsets.all(task.isCompleted ? 4 : 2.5),
                    decoration: BoxDecoration(
                      color: task.isCompleted ? AppColors.mint : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? const Color(0xFFB8E4C8)
                            : const Color(0xFF9AA69F),
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: task.isCompleted
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
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatClock(DateTime value) {
  final localValue = value.toLocal();
  final hour = switch (localValue.hour) {
    0 => 12,
    > 12 => localValue.hour - 12,
    _ => localValue.hour,
  };
  return '$hour:${localValue.minute.toString().padLeft(2, '0')}';
}

String _malayPeriod(DateTime value) {
  final hour = value.toLocal().hour;
  return switch (hour) {
    < 12 => 'pagi',
    12 => 'tengah hari',
    < 19 => 'petang',
    _ => 'malam',
  };
}

bool _hasSameTime(TaskScheduleRecord left, TaskScheduleRecord right) {
  final leftTime = left.scheduledAt.toLocal();
  final rightTime = right.scheduledAt.toLocal();
  return leftTime.hour == rightTime.hour && leftTime.minute == rightTime.minute;
}

const _malayMonths = <String>[
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

String _formatFullDate(DateTime value) =>
    '${value.day} ${_malayMonths[value.month - 1]} ${value.year}';
