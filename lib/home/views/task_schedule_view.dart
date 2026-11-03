import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/controllers/task_schedule_controller.dart';
import 'package:petani/home/models/task_schedule_record.dart';
import 'package:petani/home/repositories/home_repository.dart';
import 'package:petani/home/views/task_schedule_day_view.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/project_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';

class TaskScheduleView extends StatefulWidget {
  const TaskScheduleView({
    required this.repository,
    this.taskRepository,
    this.raisedBedRepository,
    this.projectRepository,
    super.key,
  });

  final HomeRepository repository;
  final TaskRepository? taskRepository;
  final RaisedBedRepository? raisedBedRepository;
  final ProjectRepository? projectRepository;

  @override
  State<TaskScheduleView> createState() => _TaskScheduleViewState();
}

class _TaskScheduleViewState extends State<TaskScheduleView> {
  late final TaskScheduleController _controller;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _controller = TaskScheduleController(repository: widget.repository);
    _searchController.addListener(_handleSearchChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _controller.setQuery(_searchController.text);
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) _searchController.clear();
    });
  }

  Future<void> _showPreviousMonth() async {
    _searchController.clear();
    await _controller.showPreviousMonth();
  }

  Future<void> _showNextMonth() async {
    _searchController.clear();
    await _controller.showNextMonth();
  }

  Future<void> _openDate(DateTime date) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskScheduleDayView(
          date: date,
          repository: widget.repository,
          taskRepository: widget.taskRepository,
          raisedBedRepository: widget.raisedBedRepository,
          projectRepository: widget.projectRepository,
          onScheduleChanged: _controller.load,
        ),
      ),
    );
    if (mounted) await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Jadual Tugasan'),
          centerTitle: true,
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.navigationTitle.copyWith(
            color: Colors.white,
          ),
        ),
        body: ColoredBox(
          color: Colors.white,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _CalendarContent(
              controller: _controller,
              showSearch: _showSearch,
              searchController: _searchController,
              onToggleSearch: _toggleSearch,
              onPreviousMonth: _showPreviousMonth,
              onNextMonth: _showNextMonth,
              onDateTap: _openDate,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarContent extends StatelessWidget {
  const _CalendarContent({
    required this.controller,
    required this.showSearch,
    required this.searchController,
    required this.onToggleSearch,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateTap,
  });

  final TaskScheduleController controller;
  final bool showSearch;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('task-month-calendar'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatMonth(controller.selectedMonth),
                  key: const Key('task-schedule-month-title'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CircleAction(
                key: const Key('task-schedule-previous-month'),
                icon: Icons.chevron_left_rounded,
                tooltip: 'Bulan sebelumnya',
                onTap: onPreviousMonth,
              ),
              const SizedBox(width: 8),
              _CircleAction(
                key: const Key('task-schedule-next-month'),
                icon: Icons.chevron_right_rounded,
                tooltip: 'Bulan seterusnya',
                onTap: onNextMonth,
              ),
              const SizedBox(width: 8),
              _CircleAction(
                key: const Key('task-schedule-search-button'),
                icon: showSearch ? Icons.close_rounded : Icons.search_rounded,
                tooltip: showSearch ? 'Tutup carian' : 'Cari tugasan',
                onTap: onToggleSearch,
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: showSearch
              ? Padding(
                  key: const ValueKey<String>('task-schedule-search'),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TextField(
                    key: const Key('task-schedule-search-field'),
                    controller: searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari tugasan, projek atau lokasi',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF3F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const Divider(height: 1, color: Color(0xFFDDE4E0)),
        const SizedBox(
          height: 48,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _WeekdayLabel('I'),
                _WeekdayLabel('S'),
                _WeekdayLabel('R'),
                _WeekdayLabel('K'),
                _WeekdayLabel('J'),
                _WeekdayLabel('S'),
                _WeekdayLabel('A'),
              ],
            ),
          ),
        ),
        if (controller.isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primaryAction,
            backgroundColor: AppColors.mint,
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: _CalendarGrid(
                  controller: controller,
                  onDateTap: onDateTap,
                ),
              ),
              if (controller.hasLoadError)
                Center(
                  child: FilledButton.icon(
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Muat semula jadual'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFD7DEDA))),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 21),
        color: AppColors.ink,
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.controller, required this.onDateTap});

  final TaskScheduleController controller;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final monthStart = controller.selectedMonth;
    final gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - DateTime.monday),
    );
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        key: const Key('task-schedule-calendar-grid'),
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisExtent: constraints.maxHeight / 6,
        ),
        itemCount: 42,
        itemBuilder: (context, index) {
          final date = gridStart.add(Duration(days: index));
          return _CalendarDayCell(
            date: date,
            isCurrentMonth: date.month == monthStart.month,
            isToday: DateUtils.isSameDay(date, controller.today),
            tasks: controller.tasksForDate(date),
            onTap: () => onDateTap(date),
          );
        },
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.tasks,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final List<TaskScheduleRecord> tasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'task-schedule-day-${date.year}-${date.month}-${date.day}',
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 5, 3, 4),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE8ECEA)),
              right: BorderSide(color: Color(0xFFE8ECEA)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primaryAction
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white
                          : isCurrentMonth
                          ? AppColors.ink
                          : const Color(0xFFB5BDB9),
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              for (final task in tasks.take(2)) ...[
                _CalendarTaskPill(task: task),
                const SizedBox(height: 2),
              ],
              if (tasks.length > 2)
                Text(
                  '+${tasks.length - 2}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarTaskPill extends StatelessWidget {
  const _CalendarTaskPill({required this.task});

  final TaskScheduleRecord task;

  @override
  Widget build(BuildContext context) {
    final background = _taskColor(task);
    final foreground = background == AppColors.yellow
        ? AppColors.ink
        : Colors.white;
    return Container(
      key: ValueKey<String>('task-schedule-month-task-${task.id}'),
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _taskColor(TaskScheduleRecord task) {
  if (task.isCompleted) return AppColors.primaryAction;
  return task.type.index.isEven ? AppColors.yellow : AppColors.leaf;
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

String _formatMonth(DateTime value) =>
    '${_malayMonths[value.month - 1]} ${value.year}';
