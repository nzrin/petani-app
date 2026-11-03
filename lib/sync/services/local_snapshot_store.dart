import 'package:petani/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class LocalSyncMetadata {
  const LocalSyncMetadata({
    required this.localChangedAt,
    this.linkedUserId,
    this.lastSyncedLocalChangedAt,
    this.lastRemoteUpdatedAt,
    this.lastCheckedAt,
  });

  final String? linkedUserId;
  final DateTime localChangedAt;
  final DateTime? lastSyncedLocalChangedAt;
  final DateTime? lastRemoteUpdatedAt;
  final DateTime? lastCheckedAt;
}

class LocalSnapshotStore {
  const LocalSnapshotStore(this._appDatabase);

  static const snapshotSchemaVersion = 1;

  static const _linkedUserKey = '_sync_user_id';
  static const _localChangedKey = '_sync_local_changed_at';
  static const _lastSyncedLocalKey = '_sync_last_local_changed_at';
  static const _lastRemoteKey = '_sync_last_remote_updated_at';
  static const _lastCheckedKey = '_sync_last_checked_at';
  static const _applyingRemoteKey = '_sync_applying_remote';

  static const _deleteOrder = <String>[
    'farm_activity_control_products',
    'farm_activity_raised_beds',
    'raised_bed_varieties',
    'plot_varieties',
    'disease_reports',
    'farm_activities',
    'plant_rows',
    'raised_beds',
    'plots',
  ];

  final AppDatabase _appDatabase;

  Future<LocalSyncMetadata> getMetadata() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'app_settings',
      columns: ['setting_key', 'setting_value'],
      where: 'setting_key IN (?, ?, ?, ?, ?)',
      whereArgs: const [
        _linkedUserKey,
        _localChangedKey,
        _lastSyncedLocalKey,
        _lastRemoteKey,
        _lastCheckedKey,
      ],
    );
    final settings = {
      for (final row in rows)
        row['setting_key'] as String: row['setting_value'] as String,
    };
    final now = DateTime.now().toUtc();
    return LocalSyncMetadata(
      linkedUserId: settings[_linkedUserKey],
      localChangedAt: _parseUtc(settings[_localChangedKey]) ?? now,
      lastSyncedLocalChangedAt: _parseUtc(settings[_lastSyncedLocalKey]),
      lastRemoteUpdatedAt: _parseUtc(settings[_lastRemoteKey]),
      lastCheckedAt: _parseUtc(settings[_lastCheckedKey]),
    );
  }

  Future<bool> hasUserData() async {
    final database = await _appDatabase.database;
    for (final table in const [
      'plots',
      'plant_rows',
      'farm_activities',
      'disease_reports',
    ]) {
      final result = await database.rawQuery(
        'SELECT EXISTS(SELECT 1 FROM $table LIMIT 1) AS has_data',
      );
      if ((result.single['has_data'] as int? ?? 0) == 1) return true;
    }
    return false;
  }

  Future<Map<String, Object?>> exportSnapshot() async {
    final database = await _appDatabase.database;
    final tables = <String, Object?>{};
    for (final table in AppDatabase.syncableTableNames) {
      tables[table] = await database.query(table, orderBy: _orderByFor(table));
    }
    return {'schema_version': snapshotSchemaVersion, 'tables': tables};
  }

  Future<DateTime> replaceWithEmptyDataForUser(String userId) async {
    final database = await _appDatabase.database;
    final changedAt = DateTime.now().toUtc();
    await database.transaction((transaction) async {
      await _writeSetting(transaction, _applyingRemoteKey, '1');
      for (final table in _deleteOrder) {
        await transaction.delete(table);
      }
      await transaction.delete(
        'app_settings',
        where: 'setting_key IN (?, ?, ?)',
        whereArgs: const [_lastSyncedLocalKey, _lastRemoteKey, _lastCheckedKey],
      );
      await _writeSetting(transaction, _linkedUserKey, userId);
      await _writeSetting(
        transaction,
        _localChangedKey,
        changedAt.toIso8601String(),
      );
      await _writeSetting(transaction, _applyingRemoteKey, '0');
    });
    return changedAt;
  }

  Future<void> applyRemoteSnapshot({
    required Map<String, dynamic> snapshot,
    required String userId,
    required DateTime remoteClientUpdatedAt,
    required DateTime remoteUpdatedAt,
  }) async {
    final schemaVersion = snapshot['schema_version'];
    if (schemaVersion is! int || schemaVersion > snapshotSchemaVersion) {
      throw const FormatException('Unsupported cloud snapshot schema.');
    }
    final rawTables = snapshot['tables'];
    if (rawTables is! Map) {
      throw const FormatException('Cloud snapshot is missing its tables.');
    }

    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      await _writeSetting(transaction, _applyingRemoteKey, '1');
      for (final table in _deleteOrder) {
        await transaction.delete(table);
      }

      for (final table in AppDatabase.syncableTableNames) {
        final rawRows = rawTables[table];
        if (rawRows == null) continue;
        if (rawRows is! List) {
          throw FormatException('Invalid rows for $table.');
        }
        for (final rawRow in rawRows) {
          if (rawRow is! Map) {
            throw FormatException('Invalid row in $table.');
          }
          await transaction.insert(
            table,
            Map<String, Object?>.from(rawRow),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      final localChangedAt = remoteClientUpdatedAt.toUtc().toIso8601String();
      await _writeSetting(transaction, _localChangedKey, localChangedAt);
      await _writeSetting(transaction, _lastSyncedLocalKey, localChangedAt);
      await _writeSetting(transaction, _linkedUserKey, userId);
      await _writeSetting(
        transaction,
        _lastRemoteKey,
        remoteUpdatedAt.toUtc().toIso8601String(),
      );
      await _writeSetting(
        transaction,
        _lastCheckedKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      await _writeSetting(transaction, _applyingRemoteKey, '0');
    });
  }

  Future<void> recordSuccessfulPush({
    required String userId,
    required DateTime localChangedAt,
    required DateTime remoteUpdatedAt,
  }) async {
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      await _writeSetting(transaction, _linkedUserKey, userId);
      await _writeSetting(
        transaction,
        _lastSyncedLocalKey,
        localChangedAt.toUtc().toIso8601String(),
      );
      await _writeSetting(
        transaction,
        _lastRemoteKey,
        remoteUpdatedAt.toUtc().toIso8601String(),
      );
      await _writeSetting(
        transaction,
        _lastCheckedKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    });
  }

  Future<void> recordNoChanges({
    required String userId,
    required DateTime localChangedAt,
    required DateTime remoteUpdatedAt,
  }) async {
    await recordSuccessfulPush(
      userId: userId,
      localChangedAt: localChangedAt,
      remoteUpdatedAt: remoteUpdatedAt,
    );
  }

  String? _orderByFor(String table) {
    return switch (table) {
      'farm_activity_raised_beds' => 'activity_id, raised_bed_id',
      'farm_activity_control_products' => 'activity_id, product_name',
      'raised_bed_varieties' => 'raised_bed_id, variety_code',
      _ => 'id',
    };
  }

  Future<void> _writeSetting(
    DatabaseExecutor database,
    String key,
    String value,
  ) {
    return database.insert('app_settings', {
      'setting_key': key,
      'setting_value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  DateTime? _parseUtc(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}
