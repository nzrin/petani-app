import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/database/app_database.dart';
import 'package:petani/core/services/local_notification_service.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/profile/models/notification_reminder_settings.dart';
import 'package:petani/profile/models/notification_sound_option.dart';
import 'package:petani/profile/repositories/notification_settings_repository.dart';
import 'package:petani/profile/views/notification_sound_picker_sheet.dart';
import 'package:petani/project/models/task_form_data.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';

final _notificationPreviewDate = DateTime(2026, 10, 24, 7, 30);

class ReminderSettingsView extends StatefulWidget {
  const ReminderSettingsView({super.key, this.repository, this.taskRepository});

  final NotificationSettingsRepository? repository;
  final TaskRepository? taskRepository;

  @override
  State<ReminderSettingsView> createState() => _ReminderSettingsViewState();
}

class _ReminderSettingsViewState extends State<ReminderSettingsView> {
  late final NotificationSettingsRepository _repository;
  late final TaskRepository _taskRepository;
  final _notifications = LocalNotificationService.instance;
  final _amountController = TextEditingController();

  NotificationReminderSettings _settings =
      NotificationReminderSettings.defaults;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        SqliteNotificationSettingsRepository(AppDatabase.instance);
    _taskRepository =
        widget.taskRepository ?? SqliteTaskRepository(AppDatabase.instance);
    _amountController.text = _settings.amount.toString();
    _loadSettings();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _amountController.text = settings.amount.toString();
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Tetapan peringatan tidak dapat dimuatkan.', isError: true);
    }
  }

  NotificationReminderSettings get _currentSettings {
    final parsedAmount = int.tryParse(_amountController.text);
    final amount = (parsedAmount ?? _settings.unit.defaultAmount)
        .clamp(1, _settings.unit.maximumAmount)
        .toInt();
    return NotificationReminderSettings(
      isEnabled: _settings.isEnabled,
      amount: amount,
      unit: _settings.unit,
      isSoundEnabled: _settings.isSoundEnabled,
      soundId: _settings.soundId,
    );
  }

  void _selectUnit(ReminderTimeUnit unit) {
    setState(() {
      _settings = _settings.copyWith(amount: unit.defaultAmount, unit: unit);
      _amountController.text = unit.defaultAmount.toString();
    });
  }

  void _changeAmount(int direction) {
    final current = _currentSettings.amount;
    final next = (current + (direction * _settings.unit.step))
        .clamp(1, _settings.unit.maximumAmount)
        .toInt();
    setState(() => _amountController.text = next.toString());
  }

  Future<void> _selectNotificationSound() async {
    FocusScope.of(context).unfocus();
    final selected = await showNotificationSoundPickerSheet(
      context: context,
      selectedSoundId: _settings.soundId,
    );
    if (!mounted || selected == null) return;
    setState(() => _settings = _settings.copyWith(soundId: selected.id));
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    final settings = _currentSettings;
    setState(() => _isSaving = true);

    var permissionAllowed = true;
    try {
      await _repository.saveSettings(settings);
    } catch (error, stackTrace) {
      debugPrint('Saving notification settings failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showMessage(
        'Tetapan peringatan tidak dapat disimpan. Cuba lagi.',
        isError: true,
      );
      setState(() => _isSaving = false);
      return;
    }

    var schedulingFailed = false;
    try {
      if (settings.isEnabled) {
        permissionAllowed = await _notifications.requestPermissions();
      }
      final tasks = await _taskRepository.getAllTasks();
      await _notifications.synchronizeTasks(tasks, settings);
    } catch (error, stackTrace) {
      schedulingFailed = true;
      debugPrint('Rescheduling task notifications failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;
    setState(() {
      _settings = settings;
      _amountController.text = settings.amount.toString();
      _isSaving = false;
    });
    if (schedulingFailed) {
      _showMessage(
        'Tetapan telah disimpan, tetapi jadual notifikasi belum dapat '
        'dikemas kini.',
        isError: true,
      );
      return;
    }
    _showMessage('Tetapan peringatan telah disimpan.');
    if (!permissionAllowed) await _offerNotificationSettings();
  }

  Future<void> _testRichNotification() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);

    late final bool permissionAllowed;
    try {
      permissionAllowed = await _notifications.requestPermissions();
    } catch (error, stackTrace) {
      debugPrint('Checking notification permission failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isTesting = false);
      _showMessage(
        'Status kebenaran notifikasi tidak dapat disemak. Cuba lagi.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    if (!permissionAllowed) {
      setState(() => _isTesting = false);
      await _offerNotificationSettings();
      return;
    }

    try {
      await _notifications.showRichTestNotification(
        type: FarmTaskType.insectControl,
        settings: _currentSettings,
        scheduledDate: _notificationPreviewDate,
      );
    } catch (error, stackTrace) {
      debugPrint('Rich notification test failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isTesting = false);
      _showMessage(
        'Notifikasi ujian tidak dapat dihantar. Cuba lagi.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isTesting = false);
    _showMessage('Notifikasi ujian telah dihantar.');
  }

  Future<void> _offerNotificationSettings() async {
    if (!mounted) return;
    final shouldOpenSettings = await showAppConfirmationSheet(
      context: context,
      title: 'Benarkan Notifikasi',
      description:
          'Kebenaran notifikasi Petani belum diaktifkan. Buka Tetapan '
          'peranti dan benarkan notifikasi untuk menerima peringatan '
          'tugasan.',
      confirmLabel: 'Buka Tetapan',
    );
    if (shouldOpenSettings) {
      await _notifications.openNotificationSettings();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Peringatan'),
          centerTitle: true,
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: AppTypography.navigationTitle.copyWith(
            color: AppColors.ink,
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                children: [
                  _ReminderToggleCard(
                    isEnabled: _settings.isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _currentSettings.copyWith(isEnabled: value);
                      });
                    },
                  ),
                  const SizedBox(height: 26),
                  AnimatedOpacity(
                    opacity: _settings.isEnabled ? 1 : 0.42,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !_settings.isEnabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tetapan Bunyi Notifikasi',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pilih bunyi yang dimainkan bersama peringatan.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _NotificationSoundSettingsCard(
                            isEnabled: _settings.isSoundEnabled,
                            selectedSound: NotificationSoundOption.fromId(
                              _settings.soundId,
                            ),
                            onEnabledChanged: (value) {
                              setState(
                                () => _settings = _settings.copyWith(
                                  isSoundEnabled: value,
                                ),
                              );
                            },
                            onChooseSound: _selectNotificationSound,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Ingatkan Saya',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih berapa awal peringatan perlu dihantar sebelum '
                    'tugasan bermula.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: _settings.isEnabled ? 1 : 0.42,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !_settings.isEnabled,
                      child: Column(
                        children: [
                          Row(
                            children: ReminderTimeUnit.values
                                .map(
                                  (unit) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            unit != ReminderTimeUnit.values.last
                                            ? 8
                                            : 0,
                                      ),
                                      child: _UnitPill(
                                        unit: unit,
                                        isSelected: _settings.unit == unit,
                                        onTap: () => _selectUnit(unit),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            key: const Key('reminder-counter-card'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.cellBorder),
                            ),
                            child: Row(
                              children: [
                                _StepButton(
                                  icon: Icons.remove_rounded,
                                  onPressed: () => _changeAmount(-1),
                                ),
                                Expanded(
                                  child: TextField(
                                    key: const Key('reminder-amount-field'),
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  _settings.unit.summaryLabel,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _StepButton(
                                  icon: Icons.add_rounded,
                                  onPressed: () => _changeAmount(1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ReminderTimingNotice(settings: _currentSettings),
                          const SizedBox(height: 26),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pratonton Notifikasi',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Contoh peringatan yang akan dipaparkan.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _NotificationPreviewCard(settings: _currentSettings),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            key: const Key('test-rich-notification-button'),
                            onPressed: _isTesting
                                ? null
                                : _testRichNotification,
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryAction,
                              disabledForegroundColor: AppColors.primaryAction
                                  .withValues(alpha: 0.45),
                              backgroundColor: Colors.transparent,
                              minimumSize: const Size.fromHeight(48),
                              shape: const RoundedRectangleBorder(),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            label: Text(
                              _isTesting ? 'Menghantar...' : 'Uji Notifikasi',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _isLoading
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.creamDark)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: AppButton(
                      key: const Key('save-reminder-settings-button'),
                      label: _isSaving ? 'Menyimpan...' : 'Simpan Tetapan',
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: Icons.check_rounded,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationSoundSettingsCard extends StatelessWidget {
  const _NotificationSoundSettingsCard({
    required this.isEnabled,
    required this.selectedSound,
    required this.onEnabledChanged,
    required this.onChooseSound,
  });

  final bool isEnabled;
  final NotificationSoundOption selectedSound;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onChooseSound;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('notification-sound-settings-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cellBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  color: AppColors.primaryAction,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bunyi Notifikasi',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEnabled
                          ? 'Bunyi peringatan diaktifkan.'
                          : 'Notifikasi akan dihantar tanpa bunyi.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const Key('notification-sound-toggle'),
                value: isEnabled,
                onChanged: onEnabledChanged,
                activeTrackColor: AppColors.primaryAction,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedOpacity(
            opacity: isEnabled ? 1 : 0.42,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !isEnabled,
              child: Material(
                color: const Color(0xFFF4F6F5),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const Key('choose-notification-sound-button'),
                  onTap: onChooseSound,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: AppColors.primaryAction,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedSound.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedSound.group.label,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.ink,
                          size: 28,
                        ),
                      ],
                    ),
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

class _ReminderToggleCard extends StatelessWidget {
  const _ReminderToggleCard({required this.isEnabled, required this.onChanged});

  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('reminder-toggle-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cellBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primaryAction,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peringatan Tugasan',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled ? 'Peringatan diaktifkan' : 'Peringatan dimatikan',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryAction,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _UnitPill extends StatelessWidget {
  const _UnitPill({
    required this.unit,
    required this.isSelected,
    required this.onTap,
  });

  final ReminderTimeUnit unit;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryAction : const Color(0xFFF1F3F2),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            unit.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F3F2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.primaryAction, size: 21),
        ),
      ),
    );
  }
}

class _ReminderTimingNotice extends StatelessWidget {
  const _ReminderTimingNotice({required this.settings});

  final NotificationReminderSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.creamDeep,
            size: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '${settings.summary}. Masa peringatan dikira berdasarkan '
              'masa unik yang ditetapkan pada setiap tugasan.',
              style: const TextStyle(
                color: AppColors.creamDeep,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPreviewCard extends StatelessWidget {
  const _NotificationPreviewCard({required this.settings});

  final NotificationReminderSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.58, 1],
          colors: [Color(0xFF111315), Color(0xFF34383C), Color(0xFF73787D)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x4DFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F001A18),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 50,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/icon_1024.jpg',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Kawalan Serangga',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                          ),
                          Text(
                            'Sekarang',
                            style: TextStyle(
                              color: Color(0xBFFFFFFF),
                              fontSize: 13,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.notificationMessageFor(
                          _notificationPreviewDate,
                        ),
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontSize: 14,
                          height: 1.32,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('notification-preview-task-image'),
            height: 150,
            padding: const EdgeInsets.all(8),
            child: FractionallySizedBox(
              widthFactor: 0.9,
              heightFactor: 0.9,
              child: Image.asset(
                'assets/images/tasks/insect_control.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
