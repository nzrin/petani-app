import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/controllers/task_detail_controller.dart';
import 'package:petani/project/models/control_product.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/models/task_control_product.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/project/views/fertilizer_list_view.dart';
import 'package:petani/project/views/fungicide_list_view.dart';
import 'package:petani/project/views/herbicide_list_view.dart';
import 'package:petani/project/views/insecticide_list_view.dart';
import 'package:petani/project/views/task_form_sheet.dart';
import 'package:petani/shared/formatters/malay_date_time_formatter.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';

class TaskDetailView extends StatefulWidget {
  const TaskDetailView({
    required this.task,
    required this.projectName,
    required this.plotName,
    required this.totalRaisedBeds,
    required this.raisedBeds,
    required this.repository,
    required this.onTaskChanged,
    required this.onTaskDeleted,
    super.key,
  });

  final PlotTaskRecord task;
  final String projectName;
  final String plotName;
  final int totalRaisedBeds;
  final List<RaisedBedRecord> raisedBeds;
  final TaskRepository repository;
  final ValueChanged<PlotTaskRecord> onTaskChanged;
  final ValueChanged<int> onTaskDeleted;

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late final TaskDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaskDetailController(
      task: widget.task,
      repository: widget.repository,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editTask() async {
    final result = await showTaskFormSheet(
      context: context,
      plotId: _controller.task.plotId,
      cropCode: _controller.task.cropCode,
      raisedBeds: widget.raisedBeds,
      initialTask: _controller.task,
    );
    if (!mounted || result == null) return;
    if (result.action == TaskFormSheetAction.delete) {
      await _deleteTask();
      return;
    }
    final saved = await _controller.updateTask(result.data!);
    if (!mounted) return;
    if (saved) widget.onTaskChanged(_controller.task);
    _showResult(
      saved
          ? 'Tugasan berjaya dikemas kini.'
          : 'Tugasan tidak dapat dikemas kini.',
      isError: !saved,
    );
  }

  Future<void> _deleteTask() async {
    final taskId = _controller.task.id;
    final deleted = await _controller.deleteTask();
    if (!mounted) return;
    if (!deleted) {
      _showResult('Tugasan tidak dapat dibuang.', isError: true);
      return;
    }
    widget.onTaskDeleted(taskId);
    Navigator.of(context).pop();
  }

  Future<void> _toggleCompletion() async {
    final wasCompleted = _controller.task.isCompleted;
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: wasCompleted ? 'Tugasan Diselesaikan' : 'Tugasan Selesai',
      description: wasCompleted
          ? 'Ubah tugasan ini kepada belum selesai?'
          : 'Ubah tugasan ini kepada telah selesai?',
      confirmLabel: wasCompleted ? 'Ya, Ubah' : 'Ya, Selesai',
      imagePath: wasCompleted
          ? 'assets/images/farmer_with_pump_sprayer.png'
          : 'assets/images/pump_sprayer.png',
    );
    if (!confirmed || !mounted) return;

    final saved = wasCompleted
        ? await _controller.markIncomplete()
        : await _controller.markCompleted();
    if (!mounted) return;
    if (saved) widget.onTaskChanged(_controller.task);
    _showResult(
      saved
          ? wasCompleted
                ? 'Tugasan telah ditandakan belum selesai.'
                : 'Tugasan telah ditandakan selesai.'
          : 'Status tugasan tidak dapat dikemas kini.',
      isError: !saved,
    );
  }

  void _showResult(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  Future<List<ControlProduct>?> _openProductList(PlotTaskRecord task) {
    final selectedNames = task.controlProducts
        .map((product) => product.name)
        .toSet();
    final type = task.type;
    final page = switch (type) {
      FarmTaskType.fungusControl => FungicideListView(
        initialSelectedProductNames: selectedNames,
      ),
      FarmTaskType.insectControl => InsecticideListView(
        initialSelectedProductNames: selectedNames,
      ),
      FarmTaskType.weedControl => HerbicideListView(
        initialSelectedProductNames: selectedNames,
      ),
      FarmTaskType.fertilizing => FertilizerListView(
        initialSelectedProductNames: selectedNames,
      ),
      _ => null,
    };
    if (page == null) return Future.value(null);
    return Navigator.of(context).push<List<ControlProduct>>(
      MaterialPageRoute<List<ControlProduct>>(builder: (_) => page),
    );
  }

  Future<void> _selectOrganic() async {
    final saved = await _controller.updateControlMethod(
      method: TaskControlMethod.organic,
    );
    if (!mounted) return;
    if (saved) widget.onTaskChanged(_controller.task);
    if (!saved) {
      _showResult('Jenis kawalan tidak dapat disimpan.', isError: true);
    }
  }

  Future<void> _selectChemical() async {
    final selectedProducts = await _openProductList(_controller.task);
    if (!mounted || selectedProducts == null) return;
    final saved = await _controller.updateControlMethod(
      method: TaskControlMethod.chemical,
      products: selectedProducts
          .map(
            (product) => TaskControlProduct(
              name: product.name,
              detail: product.primaryDetail,
            ),
          )
          .toList(growable: false),
    );
    if (!mounted) return;
    if (saved) widget.onTaskChanged(_controller.task);
    if (!saved) {
      _showResult('Pilihan produk tidak dapat disimpan.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final task = _controller.task;
          final rowTerminology = CropRowTerminology.forCropCode(task.cropCode);
          final isControlMethodMissing =
              task.type.supportsControlMethod && task.controlMethod == null;
          final canChangeCompletion =
              !_controller.isSaving &&
              (task.isCompleted || !isControlMethodMissing);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primaryAction,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              titleTextStyle: AppTypography.navigationTitle.copyWith(
                color: Colors.white,
              ),
              systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemStatusBarContrastEnforced: false,
              ),
              title: const Text('Butiran Tugasan'),
              centerTitle: true,
              actions: [
                TextButton(
                  key: const Key('edit-task-button'),
                  onPressed: _controller.isSaving ? null : _editTask,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text(
                    'Ubah',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskLocationBreadcrumb(
                    projectName: widget.projectName,
                    plotName: widget.plotName,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: Image.asset(
                                  task.type.imagePath,
                                  key: const Key('task-detail-type-image'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                task.type.labelForCrop(task.cropCode),
                                key: const Key('task-detail-type-label'),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 7),
                              KeyedSubtree(
                                key: const Key('task-detail-status-pill'),
                                child: _StatusPill(
                                  isCompleted: task.isCompleted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _DetailRow(
                          icon: Icons.calendar_month_outlined,
                          title: 'Tarikh Tugasan',
                          value: _formatDate(task.scheduledAt),
                        ),
                        const SizedBox(height: 24),
                        _DetailRow(
                          icon: Icons.schedule_outlined,
                          title: 'Masa Tugasan',
                          value: formatMalayTime(task.scheduledAt),
                        ),
                        if (task.type.supportsControlMethod) ...[
                          const SizedBox(height: 24),
                          _DetailRow(
                            icon: Icons.eco_outlined,
                            title: 'Jenis Kawalan',
                            detail: _ControlMethodPanel(
                              task: task,
                              enabled: !_controller.isSaving,
                              onOrganic: _selectOrganic,
                              onChemical: _selectChemical,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _DetailRow(
                          icon: Icons.grid_view_rounded,
                          title: '${rowTerminology.title} Terlibat',
                          detail: _RaisedBedDots(
                            task: task,
                            totalRaisedBeds: widget.totalRaisedBeds,
                          ),
                        ),
                        if (task.notes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _DetailRow(
                            icon: Icons.notes_rounded,
                            title: 'Nota',
                            value: task.notes,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: AppButton(
                key: const Key('complete-task-button'),
                label: task.isCompleted ? 'Tugasan Selesai' : 'Telah Selesai',
                onPressed: canChangeCompletion ? _toggleCompletion : null,
                backgroundColor: task.isCompleted
                    ? const Color.fromARGB(255, 137, 192, 157)
                    : AppColors.primaryAction,
                disabledBackgroundColor: const Color(0xFFCCD4CF),
                disabledForegroundColor: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskLocationBreadcrumb extends StatelessWidget {
  const _TaskLocationBreadcrumb({
    required this.projectName,
    required this.plotName,
  });

  final String projectName;
  final String plotName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('task-detail-location-breadcrumb'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BreadcrumbPill(
            key: const Key('task-detail-project-pill'),
            label: projectName,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Image.asset(
              'assets/images/icon_arrow_right.png',
              key: const Key('task-detail-breadcrumb-arrow'),
              width: 15,
              height: 15,
              color: AppColors.creamDeep,
              colorBlendMode: BlendMode.srcIn,
              fit: BoxFit.contain,
            ),
          ),
          _BreadcrumbPill(
            key: const Key('task-detail-plot-pill'),
            label: plotName,
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbPill extends StatelessWidget {
  const _BreadcrumbPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.creamDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.creamDeep),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.creamDeep,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.mint : AppColors.creamDark,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isCompleted ? 'Selesai' : 'Dijadualkan',
        style: TextStyle(
          color: isCompleted ? AppColors.forest : AppColors.creamDeep,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    this.value,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: AppColors.primaryAction),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (value case final value?) ...[
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (detail case final detail?) ...[
                SizedBox(height: value == null ? 8 : 11),
                detail,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RaisedBedDots extends StatelessWidget {
  const _RaisedBedDots({required this.task, required this.totalRaisedBeds});

  final PlotTaskRecord task;
  final int totalRaisedBeds;

  @override
  Widget build(BuildContext context) {
    final bedNumbers = task.includesAllRaisedBeds
        ? List<int>.generate(totalRaisedBeds, (index) => index + 1)
        : task.raisedBedNumbers;

    return Semantics(
      label:
          '${CropRowTerminology.forCropCode(task.cropCode).count(bedNumbers.length)} terlibat',
      child: Wrap(
        key: const Key('task-raised-bed-dots'),
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final bedNumber in bedNumbers)
            Container(
              key: ValueKey<String>('task-raised-bed-dot-$bedNumber'),
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.yellow,
                shape: BoxShape.circle,
              ),
              child: Text(
                bedNumber.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Color(0xFF705c21),
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlMethodPanel extends StatelessWidget {
  const _ControlMethodPanel({
    required this.task,
    required this.enabled,
    required this.onOrganic,
    required this.onChemical,
  });

  final PlotTaskRecord task;
  final bool enabled;
  final VoidCallback onOrganic;
  final VoidCallback onChemical;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const Key('task-detail-control-method-selector'),
          children: [
            Expanded(
              child: _ControlMethodPill(
                method: TaskControlMethod.organic,
                selected: task.controlMethod == TaskControlMethod.organic,
                onTap: enabled ? onOrganic : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlMethodPill(
                method: TaskControlMethod.chemical,
                selected: task.controlMethod == TaskControlMethod.chemical,
                onTap: enabled ? onChemical : null,
              ),
            ),
          ],
        ),
        if (task.controlMethod == TaskControlMethod.chemical &&
            task.controlProducts.isNotEmpty) ...[
          const SizedBox(height: 11),
          Wrap(
            key: const Key('selected-control-product-pills'),
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final product in task.controlProducts)
                Tooltip(
                  message: product.name,
                  child: Container(
                    key: ValueKey<String>(
                      'selected-control-product-${product.name}',
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      product.detail,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ControlMethodPill extends StatelessWidget {
  const _ControlMethodPill({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final TaskControlMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryAction : const Color(0xFFF1F3F2),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        key: ValueKey<String>('task-detail-control-method-${method.code}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            method.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
