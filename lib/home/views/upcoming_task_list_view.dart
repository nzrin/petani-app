import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/controllers/home_controller.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/home/navigation/upcoming_task_navigation.dart';
import 'package:petani/home/widgets/upcoming_task_card.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/shared/widgets/task_empty_state.dart';

class UpcomingTaskListView extends StatefulWidget {
  const UpcomingTaskListView({
    required this.controller,
    this.taskRepository,
    this.raisedBedRepository,
    super.key,
  });

  final HomeController controller;
  final TaskRepository? taskRepository;
  final RaisedBedRepository? raisedBedRepository;

  @override
  State<UpcomingTaskListView> createState() => _UpcomingTaskListViewState();
}

class _UpcomingTaskListViewState extends State<UpcomingTaskListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

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
          centerTitle: true,
          titleTextStyle: AppTypography.navigationTitle.copyWith(
            color: Colors.white,
          ),
          title: const Text('Tugasan Akan Datang'),
        ),
        body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final query = _searchController.text;
            final tasks = widget.controller.tasks
                .where((task) => task.matches(query))
                .toList(growable: false);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: TextField(
                    key: const Key('upcoming-task-search-field'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari tugasan, projek atau lokasi',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Kosongkan carian',
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildContent(tasks)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<UpcomingTaskRecord> tasks) {
    if (widget.controller.isLoading && widget.controller.tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAction),
      );
    }
    if (widget.controller.hasLoadError && widget.controller.tasks.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        message: 'Tugasan akan datang tidak dapat dimuatkan.',
        actionLabel: 'Cuba Lagi',
        onAction: widget.controller.loadUpcomingTasks,
      );
    }
    if (tasks.isEmpty) {
      final hasQuery = _searchController.text.trim().isNotEmpty;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: TaskEmptyState(
            title: hasQuery ? 'Tiada Hasil Carian' : 'Tiada Tugasan',
            description: hasQuery
                ? 'Tiada tugasan sepadan dengan carian anda.'
                : 'Tugasan akan datang akan dipaparkan di sini.',
            illustrationKey: const Key('empty-upcoming-task-list-tractor'),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.controller.loadUpcomingTasks,
      color: AppColors.primaryAction,
      child: ListView.builder(
        key: const Key('upcoming-task-list'),
        padding: EdgeInsets.fromLTRB(
          20,
          2,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        itemCount: tasks.length,
        itemBuilder: (context, index) => UpcomingTaskCard(
          task: tasks[index],
          showLocation: true,
          isFirstInGroup: index == 0,
          isLastInGroup: index == tasks.length - 1,
          onTap: () => openUpcomingTaskDetail(
            context: context,
            task: tasks[index],
            taskRepository: widget.taskRepository,
            raisedBedRepository: widget.raisedBedRepository,
            onChanged: widget.controller.loadUpcomingTasks,
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (actionLabel case final label?) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
