import 'package:petani/core/database/app_database.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/project_form_suggestions.dart';
import 'package:petani/project/models/project_record.dart';
import 'package:sqflite/sqflite.dart';

class ProjectNameConflictException implements Exception {
  const ProjectNameConflictException();
}

abstract interface class ProjectRepository {
  Future<int> createProject(ProjectFormData data);

  Future<void> updatePlot({required int plotId, required ProjectFormData data});

  Future<void> updateProject({
    required String currentProjectName,
    required String projectName,
    required String location,
  });

  Future<void> deletePlot(int plotId);

  Future<List<ProjectRecord>> getProjects();

  Future<ProjectFormSuggestions> getFormSuggestions();

  Future<void> deleteProject(String projectName);
}

class SqliteProjectRepository implements ProjectRepository {
  const SqliteProjectRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<ProjectRecord>> getProjects() async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery('''
      SELECT
        plots.id,
        plots.project_name,
        plots.name AS plot_name,
        plots.location,
        plots.raised_bed_count,
        plots.planted_at,
        crop_types.code AS crop_code,
        crop_types.display_name AS crop_name,
        crop_types.asset_path,
        plot_varieties.variety_code,
        plot_varieties.variety_name
      FROM plots
      INNER JOIN crop_types ON crop_types.id = plots.crop_type_id
      LEFT JOIN plot_varieties ON plot_varieties.plot_id = plots.id
      ORDER BY plots.created_at DESC, plots.id DESC, plot_varieties.id ASC
    ''');

    final projects = <String, _ProjectRecordBuilder>{};
    for (final row in rows) {
      final projectName = row['project_name'] as String;
      final projectKey = projectName.trim().toLowerCase();
      final project = projects.putIfAbsent(
        projectKey,
        () => _ProjectRecordBuilder.fromRow(projectKey, row),
      );

      final cropCode = row['crop_code'] as String;
      project.cropTypes.putIfAbsent(
        cropCode,
        () => ProjectCropType(code: cropCode, name: row['crop_name'] as String),
      );

      final plotId = row['id'] as int;
      final plot = project.plots.putIfAbsent(
        plotId,
        () => _PlotRecordBuilder.fromRow(row),
      );
      final varietyCode = row['variety_code'] as String?;
      final varietyName = row['variety_name'] as String?;
      if (varietyCode != null && varietyName != null) {
        plot.varieties.add(CropVariety(code: varietyCode, name: varietyName));
      }
    }

    return projects.values.map((project) => project.build()).toList();
  }

  @override
  Future<ProjectFormSuggestions> getFormSuggestions() async {
    final database = await _appDatabase.database;
    final projectRows = await database.rawQuery('''
      SELECT project_name, location, name AS plot_name
      FROM plots
      WHERE TRIM(project_name) != ''
      ORDER BY id DESC
    ''');
    final projectSuggestions = <String, _ProjectSuggestionBuilder>{};
    for (final row in projectRows) {
      final name = row['project_name'] as String;
      final normalizedName = _normalizeName(name);
      final project = projectSuggestions.putIfAbsent(
        normalizedName,
        () => _ProjectSuggestionBuilder(
          name: name,
          location: row['location'] as String? ?? '',
        ),
      );
      project.addPlotName(row['plot_name'] as String);
    }

    final locations = await _getDistinctValues(database, 'location');

    return ProjectFormSuggestions(
      existingProjects: projectSuggestions.values
          .map((project) => project.build())
          .toList(growable: false),
      locations: locations,
    );
  }

  Future<List<String>> _getDistinctValues(
    Database database,
    String column,
  ) async {
    final rows = await database.rawQuery('''
      SELECT DISTINCT $column AS value
      FROM plots
      WHERE $column IS NOT NULL AND TRIM($column) != ''
      ORDER BY $column COLLATE NOCASE ASC
    ''');
    return rows
        .map((row) => row['value'])
        .whereType<String>()
        .toList(growable: false);
  }

  @override
  Future<int> createProject(ProjectFormData data) async {
    if (data.varieties.isEmpty) {
      throw StateError('At least one crop variety is required.');
    }

    final database = await _appDatabase.database;
    return database.transaction((transaction) async {
      final cropTypes = await transaction.query(
        'crop_types',
        columns: ['id'],
        where: 'code = ? AND is_available = 1',
        whereArgs: [data.cropCode],
        limit: 1,
      );

      if (cropTypes.isEmpty) {
        throw StateError('Unknown or unavailable crop type: ${data.cropCode}');
      }

      final existingProjects = await transaction.query(
        'plots',
        columns: ['location'],
        where: 'LOWER(TRIM(project_name)) = LOWER(TRIM(?))',
        whereArgs: [data.projectName],
        orderBy: 'id ASC',
        limit: 1,
      );
      final existingLocation = existingProjects.isEmpty
          ? null
          : existingProjects.first['location'] as String?;
      final location = existingLocation?.trim().isNotEmpty ?? false
          ? existingLocation!
          : data.location;

      final matchingPlots = await transaction.query(
        'plots',
        columns: ['name'],
        where: 'LOWER(TRIM(project_name)) = LOWER(TRIM(?))',
        whereArgs: [data.projectName],
      );
      final normalizedPlotName = _normalizeName(data.plotName);
      final plotAlreadyExists = matchingPlots.any(
        (plot) => _normalizeName(plot['name'] as String) == normalizedPlotName,
      );
      if (plotAlreadyExists) {
        throw StateError(
          'A project cannot contain more than one plot with the same name.',
        );
      }

      final cropTypeId = cropTypes.first['id'] as int;
      final primaryVariety = data.varieties.first;
      final plotId = await transaction.insert('plots', {
        'crop_type_id': cropTypeId,
        'project_name': data.projectName,
        'location': location,
        'name': data.plotName,
        'variety_code': primaryVariety.code,
        'variety_name': primaryVariety.name,
        'raised_bed_count': data.raisedBedCount,
        'planted_at': data.plantedAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final batch = transaction.batch();
      for (final variety in data.varieties) {
        batch.insert('plot_varieties', {
          'plot_id': plotId,
          'variety_code': variety.code,
          'variety_name': variety.name,
        });
      }
      for (var bedNumber = 1; bedNumber <= data.raisedBedCount; bedNumber++) {
        batch.insert('raised_beds', {
          'plot_id': plotId,
          'bed_number': bedNumber,
        });
      }
      await batch.commit(noResult: true);
      return plotId;
    });
  }

  @override
  Future<void> updatePlot({
    required int plotId,
    required ProjectFormData data,
  }) async {
    if (data.varieties.isEmpty) {
      throw StateError('At least one crop variety is required.');
    }

    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final existingPlotRows = await transaction.query(
        'plots',
        columns: ['project_name', 'raised_bed_count'],
        where: 'id = ?',
        whereArgs: [plotId],
        limit: 1,
      );
      if (existingPlotRows.isEmpty) {
        throw StateError('Plot not found: $plotId');
      }

      final projectName = existingPlotRows.single['project_name'] as String;
      final currentRaisedBedCount =
          existingPlotRows.single['raised_bed_count'] as int;
      final matchingPlots = await transaction.query(
        'plots',
        columns: ['id', 'name'],
        where: 'LOWER(TRIM(project_name)) = LOWER(TRIM(?)) AND id != ?',
        whereArgs: [projectName, plotId],
      );
      final normalizedPlotName = _normalizeName(data.plotName);
      final plotAlreadyExists = matchingPlots.any(
        (plot) => _normalizeName(plot['name'] as String) == normalizedPlotName,
      );
      if (plotAlreadyExists) {
        throw StateError(
          'A project cannot contain more than one plot with the same name.',
        );
      }

      final cropTypes = await transaction.query(
        'crop_types',
        columns: ['id'],
        where: 'code = ? AND is_available = 1',
        whereArgs: [data.cropCode],
        limit: 1,
      );
      if (cropTypes.isEmpty) {
        throw StateError('Unknown or unavailable crop type: ${data.cropCode}');
      }

      final primaryVariety = data.varieties.first;
      await transaction.update(
        'plots',
        {
          'crop_type_id': cropTypes.single['id'],
          'name': data.plotName,
          'variety_code': primaryVariety.code,
          'variety_name': primaryVariety.name,
          'raised_bed_count': data.raisedBedCount,
          'planted_at': data.plantedAt.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [plotId],
      );

      await transaction.delete(
        'plot_varieties',
        where: 'plot_id = ?',
        whereArgs: [plotId],
      );
      final batch = transaction.batch();
      for (final variety in data.varieties) {
        batch.insert('plot_varieties', {
          'plot_id': plotId,
          'variety_code': variety.code,
          'variety_name': variety.name,
        });
      }
      if (data.raisedBedCount > currentRaisedBedCount) {
        for (
          var bedNumber = currentRaisedBedCount + 1;
          bedNumber <= data.raisedBedCount;
          bedNumber++
        ) {
          batch.insert('raised_beds', {
            'plot_id': plotId,
            'bed_number': bedNumber,
          });
        }
      }
      await batch.commit(noResult: true);

      final varietyCodes = data.varieties
          .map((variety) => variety.code)
          .toList(growable: false);
      final placeholders = List.filled(varietyCodes.length, '?').join(', ');
      await transaction.delete(
        'raised_bed_varieties',
        where:
            'raised_bed_id IN ('
            'SELECT id FROM raised_beds WHERE plot_id = ?'
            ') AND variety_code NOT IN ($placeholders)',
        whereArgs: [plotId, ...varietyCodes],
      );
      for (final variety in data.varieties) {
        await transaction.update(
          'raised_bed_varieties',
          {'variety_name': variety.name},
          where:
              'raised_bed_id IN ('
              'SELECT id FROM raised_beds WHERE plot_id = ?'
              ') AND variety_code = ?',
          whereArgs: [plotId, variety.code],
        );
      }

      if (data.raisedBedCount < currentRaisedBedCount) {
        await transaction.delete(
          'raised_beds',
          where: 'plot_id = ? AND bed_number > ?',
          whereArgs: [plotId, data.raisedBedCount],
        );
      }
    });
  }

  @override
  Future<void> updateProject({
    required String currentProjectName,
    required String projectName,
    required String location,
  }) async {
    final trimmedProjectName = projectName.trim();
    final trimmedLocation = location.trim();
    if (trimmedProjectName.isEmpty || trimmedLocation.isEmpty) {
      throw ArgumentError('Project name and location are required.');
    }

    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final projectRows = await transaction.query(
        'plots',
        distinct: true,
        columns: ['project_name'],
      );
      final normalizedProjectName = _normalizeName(trimmedProjectName);
      final hasNameConflict = projectRows.any((row) {
        final existingName = row['project_name'] as String;
        return existingName != currentProjectName &&
            _normalizeName(existingName) == normalizedProjectName;
      });
      if (hasNameConflict) {
        throw const ProjectNameConflictException();
      }

      final updatedCount = await transaction.update(
        'plots',
        {
          'project_name': trimmedProjectName,
          'location': trimmedLocation,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'project_name = ?',
        whereArgs: [currentProjectName],
      );
      if (updatedCount == 0) {
        throw StateError('Project not found: $currentProjectName');
      }
    });
  }

  @override
  Future<void> deletePlot(int plotId) async {
    final database = await _appDatabase.database;
    final deletedCount = await database.delete(
      'plots',
      where: 'id = ?',
      whereArgs: [plotId],
    );
    if (deletedCount == 0) {
      throw StateError('Plot not found: $plotId');
    }
  }

  @override
  Future<void> deleteProject(String projectName) async {
    final database = await _appDatabase.database;
    await database.delete(
      'plots',
      where: 'LOWER(TRIM(project_name)) = LOWER(TRIM(?))',
      whereArgs: [projectName],
    );
  }
}

String _normalizeName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

class _ProjectSuggestionBuilder {
  _ProjectSuggestionBuilder({required this.name, required this.location});

  final String name;
  final String location;
  final List<String> plotNames = [];
  final Set<String> _normalizedPlotNames = {};

  void addPlotName(String plotName) {
    if (_normalizedPlotNames.add(_normalizeName(plotName))) {
      plotNames.add(plotName);
    }
  }

  ExistingProjectSuggestion build() {
    return ExistingProjectSuggestion(
      name: name,
      location: location,
      plotNames: List.unmodifiable(plotNames),
    );
  }
}

class _ProjectRecordBuilder {
  _ProjectRecordBuilder({
    required this.key,
    required this.projectName,
    required this.location,
  });

  factory _ProjectRecordBuilder.fromRow(String key, Map<String, Object?> row) {
    return _ProjectRecordBuilder(
      key: key,
      projectName: row['project_name'] as String,
      location: row['location'] as String? ?? '',
    );
  }

  final String key;
  final String projectName;
  final String location;
  final Map<String, ProjectCropType> cropTypes = {};
  final Map<int, _PlotRecordBuilder> plots = {};

  ProjectRecord build() {
    return ProjectRecord(
      key: key,
      projectName: projectName,
      location: location,
      cropTypes: cropTypes.values.toList(growable: false),
      plots: plots.values.map((plot) => plot.build()).toList(growable: false),
    );
  }
}

class _PlotRecordBuilder {
  _PlotRecordBuilder({
    required this.id,
    required this.name,
    required this.cropCode,
    required this.cropName,
    required this.imagePath,
    required this.raisedBedCount,
    required this.plantedAt,
  });

  factory _PlotRecordBuilder.fromRow(Map<String, Object?> row) {
    final plantedAtValue = row['planted_at'] as String?;
    return _PlotRecordBuilder(
      id: row['id'] as int,
      name: row['plot_name'] as String,
      cropCode: row['crop_code'] as String,
      cropName: row['crop_name'] as String,
      imagePath: row['asset_path'] as String? ?? '',
      raisedBedCount: row['raised_bed_count'] as int,
      plantedAt: plantedAtValue == null
          ? null
          : DateTime.tryParse(plantedAtValue)?.toLocal(),
    );
  }

  final int id;
  final String name;
  final String cropCode;
  final String cropName;
  final String imagePath;
  final int raisedBedCount;
  final DateTime? plantedAt;
  final List<CropVariety> varieties = [];

  PlotRecord build() {
    return PlotRecord(
      id: id,
      name: name,
      cropCode: cropCode,
      cropName: cropName,
      imagePath: imagePath,
      varieties: List.unmodifiable(varieties),
      raisedBedCount: raisedBedCount,
      plantedAt: plantedAt,
    );
  }
}
