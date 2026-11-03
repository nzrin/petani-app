import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/controllers/task_form_controller.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/plot_task_record.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/views/raised_bed_picker_sheet.dart';
import 'package:petani/shared/formatters/malay_date_time_formatter.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';
import 'package:petani/shared/widgets/date_picker_sheet.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';
import 'package:petani/shared/widgets/time_picker.dart';

const _taskTypeCardAspectRatio = 0.78;
const _taskTypeLabelFontSize = 11.0;
const _taskTypeUnselectedPillColor = Color(0xFFF7F8F7);
const _taskTypesButtonHeight = 0.0;
const _taskTypesHeaderGap = 15.0;
const _destructiveRed = Color(0xFFE53935);

enum TaskFormSheetAction { save, delete }

class TaskFormSheetResult {
  const TaskFormSheetResult.save(this.data) : action = TaskFormSheetAction.save;

  const TaskFormSheetResult.delete()
    : action = TaskFormSheetAction.delete,
      data = null;

  final TaskFormSheetAction action;
  final TaskFormData? data;
}

Future<TaskFormSheetResult?> showTaskFormSheet({
  required BuildContext context,
  required int plotId,
  required String cropCode,
  required List<RaisedBedRecord> raisedBeds,
  DateTime? initialDate,
  PlotTaskRecord? initialTask,
}) {
  return showModalBottomSheet<TaskFormSheetResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskFormSheet(
      plotId: plotId,
      cropCode: cropCode,
      raisedBeds: raisedBeds,
      initialDate: initialDate,
      initialTask: initialTask,
    ),
  );
}

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    required this.plotId,
    required this.cropCode,
    required this.raisedBeds,
    this.initialDate,
    this.initialTask,
    super.key,
  });

  final int plotId;
  final String cropCode;
  final List<RaisedBedRecord> raisedBeds;
  final DateTime? initialDate;
  final PlotTaskRecord? initialTask;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final TaskFormController _controller;
  late final TextEditingController _notesController;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _controller = TaskFormController(
      plotId: widget.plotId,
      cropCode: widget.cropCode,
      raisedBeds: widget.raisedBeds,
      initialDate: widget.initialDate,
      initialTask: widget.initialTask,
    );
    _notesController = TextEditingController(text: widget.initialTask?.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
  }

  Future<void> _pickRaisedBeds() async {
    final selected = await showRaisedBedPickerSheet(
      context: context,
      cropCode: widget.cropCode,
      raisedBeds: widget.raisedBeds,
      initialSelection: _controller.selectedRaisedBedIds,
    );
    if (selected != null) _controller.setSelectedRaisedBeds(selected);
  }

  Future<void> _pickDate() async {
    final selected = await showAppDatePickerSheet(
      context: context,
      initialDate: _controller.scheduledAt,
      title: 'Tarikh Tugasan',
      description: 'Pilih tarikh tugasan anda.',
    );
    if (selected != null) _controller.setScheduledAt(selected);
  }

  Future<void> _pickTime() async {
    final selected = await showAppTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_controller.scheduledAt),
    );
    if (selected != null) {
      _controller.setScheduledTime(
        hour: selected.hour,
        minute: selected.minute,
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      imagePath: 'assets/images/trash.png',
      title: 'Buang tugasan?',
      description: 'Tugasan ini akan dipadam dan tidak boleh dipulihkan.',
      confirmLabel: 'Ya, Buang',
      confirmColor: _destructiveRed,
    );
    if (!mounted || !confirmed) return;
    Navigator.pop(context, const TaskFormSheetResult.delete());
  }

  @override
  Widget build(BuildContext context) {
    final rowTerminology = CropRowTerminology.forCropCode(widget.cropCode);
    return KeyboardInsetPadding(
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Material(
          key: const Key('task-form-sheet'),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final visibleTypes = _controller.visibleTaskTypes;
              return Column(
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.initialTask == null
                                ? 'Tambah Tugasan'
                                : 'Ubah Tugasan',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        if (widget.initialTask != null)
                          IconButton(
                            key: const Key('delete-task-button'),
                            onPressed: _confirmDelete,
                            color: _destructiveRed,
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Buang tugasan',
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Tutup',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langkah ${_step + 1} daripada 2',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (var index = 0; index < 2; index++) ...[
                              if (index > 0) const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: index <= _step
                                        ? AppColors.primaryAction
                                        : AppColors.cellBorder,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey('task-step-$_step'),
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_step == 0) ...[
                            Row(
                              children: [
                                const Expanded(
                                  child: _SectionTitle('Jenis Tugasan'),
                                ),
                                const SizedBox(width: _taskTypesHeaderGap),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _TaskTypeTabs(
                                      showAll: _controller.showAllTaskTypes,
                                      onChanged:
                                          _controller.setShowAllTaskTypes,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              key: const Key('task-type-grid'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: _taskTypeCardAspectRatio,
                                  ),
                              itemCount: visibleTypes.length,
                              itemBuilder: (context, index) {
                                final type = visibleTypes[index];
                                return _TaskTypeCard(
                                  type: type,
                                  cropCode: widget.cropCode,
                                  selected: _controller.selectedType == type,
                                  onTap: () => _controller.selectType(type),
                                );
                              },
                            ),
                          ] else ...[
                            _SectionTitle('${rowTerminology.title} Terlibat'),
                            const SizedBox(height: 5),
                            Text(
                              'Gunakan semua ${rowTerminology.lowercase} atau '
                              'pilih ${rowTerminology.lowercase} tertentu.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _ScopeCard(
                                    key: const Key('all-raised-beds-option'),
                                    icon: Icons.select_all_rounded,
                                    title: 'Semua ${rowTerminology.title}',
                                    subtitle: rowTerminology.count(
                                      widget.raisedBeds.length,
                                    ),
                                    selected: _controller.includesAllRaisedBeds,
                                    onTap: () => _controller
                                        .setIncludesAllRaisedBeds(true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ScopeCard(
                                    key: const Key(
                                      'specific-raised-beds-option',
                                    ),
                                    icon: Icons.grid_view_rounded,
                                    title: '${rowTerminology.title} Tertentu',
                                    subtitle:
                                        '${_controller.selectedRaisedBedIds.length} dipilih',
                                    selected:
                                        !_controller.includesAllRaisedBeds,
                                    onTap: () => _controller
                                        .setIncludesAllRaisedBeds(false),
                                  ),
                                ),
                              ],
                            ),
                            if (!_controller.includesAllRaisedBeds) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: const Key(
                                    'open-raised-bed-picker-button',
                                  ),
                                  onPressed: widget.raisedBeds.isEmpty
                                      ? null
                                      : _pickRaisedBeds,
                                  icon: const Icon(Icons.tune_rounded),
                                  label: Text(
                                    _controller.selectedRaisedBedIds.isEmpty
                                        ? 'Pilih ${rowTerminology.title}'
                                        : 'Ubah Pilihan '
                                              '(${_controller.selectedRaisedBedIds.length})',
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 26),
                            const _SectionTitle('Tarikh Tugasan'),
                            const SizedBox(height: 10),
                            AppDateButton(
                              key: const Key('task-date-button'),
                              label: _formatMalayDate(_controller.scheduledAt),
                              onPressed: _pickDate,
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle('Masa Tugasan'),
                            const SizedBox(height: 10),
                            AppDateButton(
                              key: const Key('task-time-button'),
                              label: formatMalayTime(_controller.scheduledAt),
                              icon: Icons.schedule_rounded,
                              onPressed: _pickTime,
                            ),
                            const SizedBox(height: 26),
                            const _SectionTitle('Nota'),
                            const SizedBox(height: 10),
                            TextField(
                              key: const Key('task-notes-field'),
                              controller: _notesController,
                              minLines: 3,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: _controller.setNotes,
                              decoration: InputDecoration(
                                hintText: 'Tulis nota tugasan (pilihan)',
                                filled: true,
                                fillColor: const Color(0xFFF1F3F2),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        if (_step == 1) ...[
                          Expanded(
                            child: AppButton.outlined(
                              key: const Key('task-back-button'),
                              label: 'Kembali',
                              onPressed: () => _goToStep(0),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: AppButton(
                            key: Key(
                              _step == 0
                                  ? 'task-next-button'
                                  : 'save-task-button',
                            ),
                            label: _step == 0
                                ? 'Seterusnya'
                                : widget.initialTask == null
                                ? 'Simpan Tugasan'
                                : 'Simpan',
                            onPressed: _step == 0
                                ? _controller.selectedType == null
                                      ? null
                                      : () => _goToStep(1)
                                : _controller.canSubmit
                                ? () => Navigator.pop(
                                    context,
                                    TaskFormSheetResult.save(
                                      _controller.buildResult(),
                                    ),
                                  )
                                : null,
                            disabledBackgroundColor: const Color(0xFFCCD4CF),
                            disabledForegroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TaskTypeTabs extends StatelessWidget {
  const _TaskTypeTabs({required this.showAll, required this.onChanged});

  final bool showAll;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('task-type-tabs'),
      padding: const EdgeInsets.all(3),
      decoration: const ShapeDecoration(
        color: AppColors.mint,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final all in [false, true])
            Flexible(
              child: Semantics(
                selected: showAll == all,
                child: TextButton(
                  key: Key(
                    all ? 'task-types-all-tab' : 'task-types-suitable-tab',
                  ),
                  onPressed: () => onChanged(all),
                  style: TextButton.styleFrom(
                    foregroundColor: showAll == all
                        ? Colors.white
                        : AppColors.primaryAction,
                    backgroundColor: showAll == all
                        ? AppColors.primaryAction
                        : Colors.transparent,
                    minimumSize: const Size(0, _taskTypesButtonHeight),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.standard,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  child: Text(
                    all ? 'Semua Tugasan' : 'Tugasan Sesuai',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TaskTypeCard extends StatelessWidget {
  const _TaskTypeCard({
    required this.type,
    required this.cropCode,
    required this.selected,
    required this.onTap,
  });

  final FarmTaskType type;
  final String cropCode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>('task-type-${type.code}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primaryAction
                  : const Color(0xFFDDE3E0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    type.imagePath,
                    key: ValueKey<String>('task-type-image-${type.code}'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                key: ValueKey<String>('task-type-label-pill-${type.code}'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryAction
                      : _taskTypeUnselectedPillColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  type.labelForCrop(cropCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: _taskTypeLabelFontSize,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primaryAction
                  : const Color(0xFFDDE3E0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primaryAction : AppColors.muted,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMalayDate(DateTime value) {
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
