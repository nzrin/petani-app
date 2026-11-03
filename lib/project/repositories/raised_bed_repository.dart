import 'package:petani/core/database/app_database.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/raised_bed_record.dart';

abstract interface class RaisedBedRepository {
  Future<List<RaisedBedRecord>> getRaisedBeds(int plotId);

  Future<void> saveSeedlingCount({
    required int plotId,
    required int bedNumber,
    required int seedlingCount,
  });

  Future<void> saveRaisedBedDetails({
    required int plotId,
    required int bedNumber,
    required int seedlingCount,
    required List<CropVariety> varieties,
  });

  Future<void> saveBulkRaisedBedDetails({
    required int plotId,
    required int seedlingCount,
    required bool onlyUnset,
    required List<CropVariety> varieties,
  });
}

class SqliteRaisedBedRepository implements RaisedBedRepository {
  const SqliteRaisedBedRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<RaisedBedRecord>> getRaisedBeds(int plotId) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'raised_beds',
      where: 'plot_id = ?',
      whereArgs: [plotId],
      orderBy: 'bed_number ASC',
    );
    final records = rows
        .map(
          (row) => RaisedBedRecord(
            id: row['id'] as int,
            plotId: row['plot_id'] as int,
            bedNumber: row['bed_number'] as int,
            seedlingCount: row['seedling_count'] as int?,
          ),
        )
        .toList(growable: false);
    if (records.isEmpty) return records;

    final varietyRows = await database.rawQuery(
      '''
      SELECT
        raised_bed_varieties.raised_bed_id,
        raised_bed_varieties.variety_code,
        raised_bed_varieties.variety_name
      FROM raised_bed_varieties
      INNER JOIN raised_beds
        ON raised_beds.id = raised_bed_varieties.raised_bed_id
      WHERE raised_beds.plot_id = ?
      ORDER BY raised_bed_varieties.variety_code ASC
      ''',
      [plotId],
    );
    final varietiesByBedId = <int, List<CropVariety>>{};
    for (final row in varietyRows) {
      varietiesByBedId
          .putIfAbsent(row['raised_bed_id'] as int, () => [])
          .add(
            CropVariety(
              code: row['variety_code'] as String,
              name: row['variety_name'] as String,
            ),
          );
    }
    return records
        .map(
          (record) => record.withDetails(
            seedlingCount: record.seedlingCount,
            varieties: varietiesByBedId[record.id] ?? const [],
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveRaisedBedDetails({
    required int plotId,
    required int bedNumber,
    required int seedlingCount,
    required List<CropVariety> varieties,
  }) async {
    if (seedlingCount < 0) {
      throw ArgumentError.value(
        seedlingCount,
        'seedlingCount',
        'Seedling count cannot be negative.',
      );
    }

    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final raisedBedRows = await transaction.query(
        'raised_beds',
        columns: ['id'],
        where: 'plot_id = ? AND bed_number = ?',
        whereArgs: [plotId, bedNumber],
        limit: 1,
      );
      if (raisedBedRows.isEmpty) {
        throw StateError(
          'Raised bed $bedNumber does not exist in plot $plotId.',
        );
      }

      final availableVarietyRows = await transaction.query(
        'plot_varieties',
        columns: ['variety_code', 'variety_name'],
        where: 'plot_id = ?',
        whereArgs: [plotId],
      );
      final availableVarieties = {
        for (final row in availableVarietyRows)
          row['variety_code'] as String: row['variety_name'] as String,
      };
      if (varieties.any(
        (variety) => availableVarieties[variety.code] != variety.name,
      )) {
        throw StateError('A selected variety does not belong to this plot.');
      }

      final raisedBedId = raisedBedRows.single['id'] as int;
      final storedCount = seedlingCount == 0 ? null : seedlingCount;
      await transaction.update(
        'raised_beds',
        {
          'seedling_count': storedCount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [raisedBedId],
      );
      await transaction.delete(
        'raised_bed_varieties',
        where: 'raised_bed_id = ?',
        whereArgs: [raisedBedId],
      );
      final batch = transaction.batch();
      for (final variety in varieties) {
        batch.insert('raised_bed_varieties', {
          'raised_bed_id': raisedBedId,
          'variety_code': variety.code,
          'variety_name': variety.name,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> saveSeedlingCount({
    required int plotId,
    required int bedNumber,
    required int seedlingCount,
  }) async {
    if (seedlingCount < 0) {
      throw ArgumentError.value(
        seedlingCount,
        'seedlingCount',
        'Seedling count cannot be negative.',
      );
    }

    final database = await _appDatabase.database;
    final storedCount = seedlingCount == 0 ? null : seedlingCount;
    final updatedRows = await database.update(
      'raised_beds',
      {
        'seedling_count': storedCount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'plot_id = ? AND bed_number = ?',
      whereArgs: [plotId, bedNumber],
    );
    if (updatedRows == 0) {
      throw StateError('Raised bed $bedNumber does not exist in plot $plotId.');
    }
  }

  @override
  Future<void> saveBulkRaisedBedDetails({
    required int plotId,
    required int seedlingCount,
    required bool onlyUnset,
    required List<CropVariety> varieties,
  }) async {
    if (seedlingCount < 0) {
      throw ArgumentError.value(
        seedlingCount,
        'seedlingCount',
        'Seedling count cannot be negative.',
      );
    }

    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final availableVarietyRows = await transaction.query(
        'plot_varieties',
        columns: ['variety_code', 'variety_name'],
        where: 'plot_id = ?',
        whereArgs: [plotId],
      );
      final availableVarieties = {
        for (final row in availableVarietyRows)
          row['variety_code'] as String: row['variety_name'] as String,
      };
      if (varieties.isEmpty ||
          varieties.any(
            (variety) => availableVarieties[variety.code] != variety.name,
          )) {
        throw StateError('A selected variety does not belong to this plot.');
      }

      final targetRows = await transaction.query(
        'raised_beds',
        columns: ['id'],
        where: onlyUnset
            ? 'plot_id = ? AND seedling_count IS NULL'
            : 'plot_id = ?',
        whereArgs: [plotId],
      );
      if (targetRows.isEmpty) return;

      final storedCount = seedlingCount == 0 ? null : seedlingCount;
      final updatedAt = DateTime.now().toUtc().toIso8601String();
      final batch = transaction.batch();
      for (final row in targetRows) {
        final raisedBedId = row['id'] as int;
        batch.update(
          'raised_beds',
          {'seedling_count': storedCount, 'updated_at': updatedAt},
          where: 'id = ?',
          whereArgs: [raisedBedId],
        );
        batch.delete(
          'raised_bed_varieties',
          where: 'raised_bed_id = ?',
          whereArgs: [raisedBedId],
        );
        for (final variety in varieties) {
          batch.insert('raised_bed_varieties', {
            'raised_bed_id': raisedBedId,
            'variety_code': variety.code,
            'variety_name': variety.name,
          });
        }
      }
      await batch.commit(noResult: true);
    });
  }
}
