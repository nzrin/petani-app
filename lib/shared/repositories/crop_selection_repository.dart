import 'package:petani/core/database/app_database.dart';
import 'package:petani/shared/models/crop_option.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class CropSelectionRepository {
  Future<void> saveSelectedCrop(CropOption crop);

  Future<String?> getSelectedCropCode();

  Future<void> clearSelectedCrop();
}

class SqliteCropSelectionRepository implements CropSelectionRepository {
  const SqliteCropSelectionRepository(this._appDatabase);

  static const _selectedCropKey = 'selected_crop_code';

  final AppDatabase _appDatabase;

  @override
  Future<void> saveSelectedCrop(CropOption crop) async {
    final database = await _appDatabase.database;
    await database.insert('app_settings', {
      'setting_key': _selectedCropKey,
      'setting_value': crop.code,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<String?> getSelectedCropCode() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: [_selectedCropKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['setting_value'] as String?;
  }

  @override
  Future<void> clearSelectedCrop() async {
    final database = await _appDatabase.database;
    await database.delete(
      'app_settings',
      where: 'setting_key = ?',
      whereArgs: [_selectedCropKey],
    );
  }
}
