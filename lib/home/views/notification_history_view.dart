import 'package:flutter/material.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';
import 'package:petani/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/models/task_notification_record.dart';
import 'package:petani/core/repositories/notification_history_repository.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/navigation/upcoming_task_navigation.dart';
import 'package:petani/project/repositories/raised_bed_repository.dart';
import 'package:petani/project/repositories/task_repository.dart';
import 'package:petani/shared/formatters/malay_date_time_formatter.dart';
import 'package:petani/shared/widgets/app_confirmation_sheet.dart';
import 'package:petani/shared/widgets/task_empty_state.dart';

class NotificationHistoryView extends StatefulWidget {
  const NotificationHistoryView({
    required this.repository,
    this.taskRepository,
    this.raisedBedRepository,
    super.key,
  });

  final NotificationHistoryRepository repository;
  final TaskRepository? taskRepository;
  final RaisedBedRepository? raisedBedRepository;

  @override
  State<NotificationHistoryView> createState() =>
      _NotificationHistoryViewState();
}

class _NotificationHistoryViewState extends State<NotificationHistoryView> {
  List<TaskNotificationRecord> _notifications = const [];
  bool _isLoading = true;
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    try {
      final notifications = await widget.repository.getReceivedNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
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

  Future<void> _openTask(TaskNotificationRecord notification) async {
    if (!notification.isRead) {
      try {
        await widget.repository.markAsRead(notification.id);
        if (!mounted) return;
        setState(() {
          _notifications = _notifications
              .map(
                (item) => item.id == notification.id
                    ? item.copyWith(isRead: true)
                    : item,
              )
              .toList(growable: false);
        });
      } catch (_) {
        if (!mounted) return;
        AppToast.show(
          context,
          'Status notifikasi tidak dapat dikemas kini.',
          isError: true,
        );
      }
    }
    if (!notification.isTaskAvailable) {
      AppToast.show(context, 'Tugasan ini tidak lagi tersedia.', isError: true);
      return;
    }
    await openTaskDetailByReference(
      context: context,
      taskId: notification.taskId,
      plotId: notification.plotId,
      projectName: notification.projectName,
      plotName: notification.plotName,
      taskRepository: widget.taskRepository,
      raisedBedRepository: widget.raisedBedRepository,
      onChanged: _loadNotifications,
    );
  }

  Future<void> _showNotificationOptions() async {
    final action = await showModalBottomSheet<_NotificationListAction>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          KeyboardInsetPadding(child: const _NotificationOptionsSheet()),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _NotificationListAction.markAllRead:
        await _markAllAsRead();
      case _NotificationListAction.deleteAll:
        await _confirmAndDeleteAll();
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await widget.repository.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList(growable: false);
      });
      _showMessage('Semua notifikasi telah ditanda sebagai dibaca.');
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Status notifikasi tidak dapat dikemas kini.',
        isError: true,
      );
    }
  }

  Future<void> _confirmAndDeleteAll() async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: 'Delete Semua Notifikasi?',
      description:
          'Semua sejarah notifikasi yang diterima akan dipadam dan tidak '
          'boleh dipulihkan.',
      confirmLabel: 'Delete Semua',
      confirmColor: const Color(0xFFE84545),
    );
    if (!mounted || !confirmed) return;

    try {
      await widget.repository.deleteAllReceivedNotifications();
      if (!mounted) return;
      setState(() => _notifications = const []);
      _showMessage('Semua notifikasi telah dipadam.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Notifikasi tidak dapat dipadam. Cuba lagi.', isError: true);
    }
  }

  Future<bool> _deleteNotification(TaskNotificationRecord notification) async {
    try {
      await widget.repository.deleteReceivedNotification(notification.id);
      return true;
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Notifikasi tidak dapat dipadam. Cuba lagi.',
          isError: true,
        );
      }
      return false;
    }
  }

  void _removeDeletedNotification(TaskNotificationRecord notification) {
    setState(() {
      _notifications = _notifications
          .where((item) => item.id != notification.id)
          .toList(growable: false);
    });
    _showMessage('Notifikasi telah dipadam.');
  }

  void _showMessage(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
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
          title: const Text('Notifikasi'),
          centerTitle: true,
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.navigationTitle.copyWith(
            color: Colors.white,
          ),
          actions: [
            TextButton(
              key: const Key('notification-settings-button'),
              onPressed: _showNotificationOptions,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                'Set',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildContent(),
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
          onPressed: _loadNotifications,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Cuba Lagi'),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 12, 32, 40),
          child: TaskEmptyState(
            title: 'Tiada Notifikasi',
            description:
                'Peringatan tugasan yang telah diterima akan dipaparkan di sini.',
            illustrationKey: Key('empty-notification-history-tractor'),
          ),
        ),
      );
    }

    final groups = _groupNotificationsByDate(_notifications);
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primaryAction,
      child: ListView.separated(
        key: const Key('notification-history-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.paddingOf(context).bottom + 28,
        ),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: 22),
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(group.date),
                key: ValueKey<String>(
                  'notification-date-${group.date.toIso8601String()}',
                ),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              for (
                var itemIndex = 0;
                itemIndex < group.notifications.length;
                itemIndex++
              ) ...[
                _NotificationHistoryCell(
                  notification: group.notifications[itemIndex],
                  isFirstInGroup: itemIndex == 0,
                  isLastInGroup: itemIndex == group.notifications.length - 1,
                  onTap: () => _openTask(group.notifications[itemIndex]),
                  onDelete: () =>
                      _deleteNotification(group.notifications[itemIndex]),
                  onDismissed: () => _removeDeletedNotification(
                    group.notifications[itemIndex],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NotificationHistoryCell extends StatelessWidget {
  const _NotificationHistoryCell({
    required this.notification,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.onTap,
    required this.onDelete,
    required this.onDismissed,
  });

  final TaskNotificationRecord notification;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final hasContext =
        notification.projectName.isNotEmpty || notification.plotName.isNotEmpty;
    const radius = Radius.circular(18);
    const borderSide = BorderSide(color: Color(0xFFE5EAE7));
    final borderRadius = BorderRadius.vertical(
      top: isFirstInGroup ? radius : Radius.zero,
      bottom: isLastInGroup ? radius : Radius.zero,
    );
    return Dismissible(
      key: ValueKey<String>('notification-slide-${notification.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.34},
      movementDuration: const Duration(milliseconds: 220),
      resizeDuration: const Duration(milliseconds: 220),
      confirmDismiss: (_) => onDelete(),
      onDismissed: (_) => onDismissed(),
      background: Container(
        key: ValueKey<String>(
          'notification-delete-background-${notification.id}',
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFE33434),
          borderRadius: borderRadius,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 25),
            SizedBox(height: 3),
            Text(
              'Padam',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            key: ValueKey<String>('notification-history-${notification.id}'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border(
                top: borderSide,
                left: borderSide,
                right: borderSide,
                bottom: isLastInGroup ? borderSide : BorderSide.none,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox.square(
                  key: ValueKey<String>(
                    'notification-task-image-${notification.id}',
                  ),
                  dimension: 68,
                  child: Image.asset(
                    notification.type.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatMalayTime(notification.receivedAt),
                        style: const TextStyle(
                          color: AppColors.primaryAction,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (hasContext) ...[
                        const SizedBox(height: 7),
                        Text(
                          [
                            notification.projectName,
                            notification.plotName,
                          ].where((value) => value.isNotEmpty).join('  ›  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox.square(
                  dimension: 10,
                  child: notification.isRead
                      ? null
                      : DecoratedBox(
                          key: ValueKey<String>(
                            'notification-unread-dot-${notification.id}',
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _NotificationListAction { markAllRead, deleteAll }

class _NotificationOptionsSheet extends StatelessWidget {
  const _NotificationOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('notification-options-sheet'),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D9D7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tetapan Notifikasi',
                  key: const Key('notification-options-title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('mark-all-notifications-read-button'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: () =>
                    Navigator.pop(context, _NotificationListAction.markAllRead),
                title: const Text('Tanda Semua Notifikasi Telah Dibaca'),
              ),
              ListTile(
                key: const Key('delete-all-notifications-button'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: () =>
                    Navigator.pop(context, _NotificationListAction.deleteAll),
                title: const Text(
                  'Delete Semua Notifikasi',
                  style: TextStyle(color: Color(0xFFE84545)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDateGroup {
  const _NotificationDateGroup({
    required this.date,
    required this.notifications,
  });

  final DateTime date;
  final List<TaskNotificationRecord> notifications;
}

List<_NotificationDateGroup> _groupNotificationsByDate(
  List<TaskNotificationRecord> notifications,
) {
  final groups = <_NotificationDateGroup>[];
  final sortedNotifications = List<TaskNotificationRecord>.of(notifications)
    ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  for (final notification in sortedNotifications) {
    final localDate = notification.receivedAt.toLocal();
    final date = DateTime(localDate.year, localDate.month, localDate.day);
    if (groups.isEmpty || groups.last.date != date) {
      groups.add(
        _NotificationDateGroup(date: date, notifications: [notification]),
      );
      continue;
    }
    groups.last.notifications.add(notification);
  }
  return groups;
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
  final localValue = value.toLocal();
  return '${localValue.day} ${months[localValue.month - 1]} ${localValue.year}';
}
