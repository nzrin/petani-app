import 'package:flutter/material.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/home/models/upcoming_task_record.dart';
import 'package:petani/shared/formatters/malay_date_time_formatter.dart';

class UpcomingTaskCard extends StatelessWidget {
  const UpcomingTaskCard({
    required this.task,
    this.showLocation = false,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.onTap,
    super.key,
  });

  final UpcomingTaskRecord task;
  final bool showLocation;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(18);
    const borderSide = BorderSide(color: Color(0xFFE5EAE7));
    final borderRadius = BorderRadius.vertical(
      top: isFirstInGroup ? radius : Radius.zero,
      bottom: isLastInGroup ? radius : Radius.zero,
    );
    return Material(
      color: Colors.white,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          key: ValueKey<String>('upcoming-task-${task.id}'),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border(
              top: borderSide,
              left: borderSide,
              right: borderSide,
              bottom: isLastInGroup ? borderSide : BorderSide.none,
            ),
          ),
          child: _TaskCardContent(task: task, showLocation: showLocation),
        ),
      ),
    );
  }
}

class _TaskCardContent extends StatelessWidget {
  const _TaskCardContent({required this.task, required this.showLocation});

  final UpcomingTaskRecord task;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(task.scheduledAt, DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 52,
          child: Image.asset(task.type.imagePath, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                task.contextLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (showLocation && task.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        task.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatUpcomingTaskDate(task.scheduledAt),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isToday ? const Color(0xFFB85522) : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              formatMalayTime(task.scheduledAt),
              key: ValueKey<String>('upcoming-task-time-${task.id}'),
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String formatUpcomingTaskDate(DateTime value, {DateTime? now}) {
  final current = _dateOnly(now ?? DateTime.now());
  final date = _dateOnly(value);
  final difference = date.difference(current).inDays;
  if (difference == 0) return 'Hari ini';
  if (difference == 1) return 'Esok';

  const months = <String>[
    'Jan',
    'Feb',
    'Mac',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ogo',
    'Sep',
    'Okt',
    'Nov',
    'Dis',
  ];
  return '${date.day} ${months[date.month - 1]}\n${date.year}';
}

DateTime _dateOnly(DateTime value) {
  final localValue = value.toLocal();
  return DateTime(localValue.year, localValue.month, localValue.day);
}
