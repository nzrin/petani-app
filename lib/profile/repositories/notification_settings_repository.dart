import 'package:petani/core/database/app_database.dart';
import 'package:petani/profile/models/notification_reminder_settings.dart';
import 'package:petani/profile/models/notification_sound_option.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class NotificationSettingsRepository {
  Future<NotificationReminderSettings> getSettings();

  Future<void> saveSettings(NotificationReminderSettings settings);
}

class SqliteNotificationSettingsRepository
    implements NotificationSettingsRepository {
  const SqliteNotificationSettingsRepository(this._appDatabase);

  static const _enabledKey = 'task_reminder_enabled';
  static const _amountKey = 'task_reminder_amount';
  static const _unitKey = 'task_reminder_unit';
  static const _soundEnabledKey = 'task_reminder_sound_enabled';
  static const _soundIdKey = 'task_reminder_sound_id';

  final AppDatabase _appDatabase;

  @override
  Future<NotificationReminderSettings> getSettings() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'app_settings',
      columns: ['setting_key', 'setting_value'],
      where: 'setting_key IN (?, ?, ?, ?, ?)',
      whereArgs: [
        _enabledKey,
        _amountKey,
        _unitKey,
        _soundEnabledKey,
        _soundIdKey,
      ],
    );
    final values = {
      for (final row in rows)
        row['setting_key'] as String: row['setting_value'] as String,
    };
    final unit = ReminderTimeUnit.fromCode(values[_unitKey]);
    final parsedAmount = int.tryParse(values[_amountKey] ?? '');
    final amount = (parsedAmount ?? unit.defaultAmount).clamp(
      1,
      unit.maximumAmount,
    );
    return NotificationReminderSettings(
      isEnabled: values[_enabledKey] != '0',
      amount: amount,
      unit: unit,
      isSoundEnabled: values[_soundEnabledKey] != '0',
      soundId: NotificationSoundOption.fromId(values[_soundIdKey]).id,
    );
  }

  @override
  Future<void> saveSettings(NotificationReminderSettings settings) async {
    final database = await _appDatabase.database;
    final updatedAt = DateTime.now().toUtc().toIso8601String();
    final batch = database.batch();
    for (final entry in <String, String>{
      _enabledKey: settings.isEnabled ? '1' : '0',
      _amountKey: settings.amount.toString(),
      _unitKey: settings.unit.code,
      _soundEnabledKey: settings.isSoundEnabled ? '1' : '0',
      _soundIdKey: NotificationSoundOption.fromId(settings.soundId).id,
    }.entries) {
      batch.insert('app_settings', {
        'setting_key': entry.key,
        'setting_value': entry.value,
        'updated_at': updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
