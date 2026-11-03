import 'package:petani/shared/formatters/malay_date_time_formatter.dart';
import 'package:petani/profile/models/notification_sound_option.dart';

enum ReminderTimeUnit {
  days('days', 'Hari', 'hari', 1, 30, 1),
  hours('hours', 'Jam', 'jam', 12, 48, 1),
  minutes('minutes', 'Minit', 'minit', 30, 120, 5);

  const ReminderTimeUnit(
    this.code,
    this.label,
    this.summaryLabel,
    this.defaultAmount,
    this.maximumAmount,
    this.step,
  );

  final String code;
  final String label;
  final String summaryLabel;
  final int defaultAmount;
  final int maximumAmount;
  final int step;

  static ReminderTimeUnit fromCode(String? code) {
    return values.firstWhere(
      (unit) => unit.code == code,
      orElse: () => ReminderTimeUnit.hours,
    );
  }
}

class NotificationReminderSettings {
  const NotificationReminderSettings({
    required this.isEnabled,
    required this.amount,
    required this.unit,
    this.isSoundEnabled = true,
    this.soundId = NotificationSoundOption.defaultId,
  });

  static const defaults = NotificationReminderSettings(
    isEnabled: true,
    amount: 12,
    unit: ReminderTimeUnit.hours,
    isSoundEnabled: true,
    soundId: NotificationSoundOption.defaultId,
  );

  final bool isEnabled;
  final int amount;
  final ReminderTimeUnit unit;
  final bool isSoundEnabled;
  final String soundId;

  NotificationSoundOption get sound => NotificationSoundOption.fromId(soundId);

  Duration get leadTime => switch (unit) {
    ReminderTimeUnit.days => Duration(days: amount),
    ReminderTimeUnit.hours => Duration(hours: amount),
    ReminderTimeUnit.minutes => Duration(minutes: amount),
  };

  String get summary => isEnabled
      ? '$amount ${unit.summaryLabel} sebelum tugasan'
      : 'Peringatan tugasan dimatikan';

  String notificationMessageFor(DateTime scheduledAt) {
    final localDate = scheduledAt.toLocal();
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
    final formattedDate =
        '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
    return 'Ini adalah peringatan mesra berkenaan tugasan yang telah anda '
        'rekodkan. Tugasan ini dijadualkan akan bermula pada pukul '
        '${formatMalayTime(localDate)}, $formattedDate.';
  }

  NotificationReminderSettings copyWith({
    bool? isEnabled,
    int? amount,
    ReminderTimeUnit? unit,
    bool? isSoundEnabled,
    String? soundId,
  }) {
    return NotificationReminderSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      soundId: soundId ?? this.soundId,
    );
  }
}
