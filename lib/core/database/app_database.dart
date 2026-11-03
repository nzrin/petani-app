import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const databaseName = 'farm_management.db';
  static const databaseVersion = 18;
  // Added in v18; keep existing crop IDs stable during upgrades.
  static const _additionalCropTypes = <Map<String, Object?>>[
    {
      'code': 'sweet_potato',
      'display_name': 'Ubi Keledek',
      'asset_path': 'assets/images/seeds/sweet_potato.png',
      'is_available': 1,
    },
    {
      'code': 'corn',
      'display_name': 'Jagung',
      'asset_path': 'assets/images/seeds/corn.png',
      'is_available': 1,
    },
    {
      'code': 'cassava',
      'display_name': 'Ubi Kayu',
      'asset_path': 'assets/images/seeds/cassava.png',
      'is_available': 1,
    },
    {
      'code': 'durian',
      'display_name': 'Durian',
      'asset_path': 'assets/images/seeds/durian.png',
      'is_available': 1,
    },
    {
      'code': 'watermelon',
      'display_name': 'Tembikai',
      'asset_path': 'assets/images/seeds/watermelon.png',
      'is_available': 1,
    },
    {
      'code': 'rock_melon',
      'display_name': 'Rock Melon',
      'asset_path': 'assets/images/seeds/rock_melon.png',
      'is_available': 1,
    },
    {
      'code': 'strawberry',
      'display_name': 'Strawberi',
      'asset_path': 'assets/images/seeds/strawberry.png',
      'is_available': 1,
    },
    {
      'code': 'chilli',
      'display_name': 'Cili',
      'asset_path': 'assets/images/seeds/chilli.png',
      'is_available': 1,
    },
    {
      'code': 'cucumber',
      'display_name': 'Timun',
      'asset_path': 'assets/images/seeds/cucumber.png',
      'is_available': 1,
    },
    {
      'code': 'eggplant',
      'display_name': 'Terung',
      'asset_path': 'assets/images/seeds/eggplant.png',
      'is_available': 1,
    },
    {
      'code': 'lime',
      'display_name': 'Limau Nipis',
      'asset_path': 'assets/images/seeds/lime.png',
      'is_available': 0,
    },
    {
      'code': 'pandan',
      'display_name': 'Pandan',
      'asset_path': 'assets/images/seeds/pandan.png',
      'is_available': 0,
    },
    {
      'code': 'lemongrass',
      'display_name': 'Serai',
      'asset_path': 'assets/images/seeds/lemongrass.png',
      'is_available': 0,
    },
    {
      'code': 'tomato',
      'display_name': 'Tomato',
      'asset_path': 'assets/images/seeds/tomato.png',
      'is_available': 0,
    },
    {
      'code': 'turmeric',
      'display_name': 'Kunyit',
      'asset_path': 'assets/images/seeds/turmeric.png',
      'is_available': 0,
    },
    {
      'code': 'calamansi',
      'display_name': 'Limau Kasturi',
      'asset_path': 'assets/images/seeds/calamansi.png',
      'is_available': 0,
    },
    {
      'code': 'kesum',
      'display_name': 'Kesum',
      'asset_path': 'assets/images/seeds/kesum.png',
      'is_available': 0,
    },
  ];

  static const syncableTableNames = <String>[
    'plots',
    'plant_rows',
    'plot_varieties',
    'raised_beds',
    'raised_bed_varieties',
    'farm_activities',
    'farm_activity_raised_beds',
    'farm_activity_control_products',
    'disease_reports',
  ];

  Database? _database;

  Future<Database> get database async {
    final currentDatabase = _database;
    if (currentDatabase != null && currentDatabase.isOpen) {
      return currentDatabase;
    }

    final databasePath = path.join(await getDatabasesPath(), databaseName);
    _database = await openDatabase(
      databasePath,
      version: databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> ensureTaskNotificationHistorySchema() async {
    final currentDatabase = await database;
    await currentDatabase.execute('''
      CREATE TABLE IF NOT EXISTS task_notification_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notification_id INTEGER NOT NULL,
        task_id INTEGER NOT NULL,
        plot_id INTEGER NOT NULL,
        task_type TEXT NOT NULL,
        crop_code TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        reminder_at TEXT NOT NULL,
        task_scheduled_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        canceled_at TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (task_id, reminder_at)
      )
    ''');
    await currentDatabase.execute(
      'CREATE INDEX IF NOT EXISTS '
      'index_task_notification_history_reminder_at '
      'ON task_notification_history (reminder_at)',
    );
    await currentDatabase.execute(
      'CREATE INDEX IF NOT EXISTS index_task_notification_history_task_id '
      'ON task_notification_history (task_id)',
    );
    await _ensureTaskNotificationReadColumn(currentDatabase);
    await currentDatabase.execute(
      'CREATE INDEX IF NOT EXISTS '
      'index_task_notification_history_read_reminder_at '
      'ON task_notification_history (is_read, reminder_at)',
    );
    return currentDatabase;
  }

  Future<void> _ensureTaskNotificationReadColumn(
    DatabaseExecutor database,
  ) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info(task_notification_history)',
    );
    if (columns.any((column) => column['name'] == 'is_read')) return;
    try {
      await database.execute(
        'ALTER TABLE task_notification_history '
        'ADD COLUMN is_read INTEGER NOT NULL DEFAULT 0',
      );
    } on DatabaseException {
      final refreshedColumns = await database.rawQuery(
        'PRAGMA table_info(task_notification_history)',
      );
      if (!refreshedColumns.any((column) => column['name'] == 'is_read')) {
        rethrow;
      }
    }
  }

  Future<void> close() async {
    final currentDatabase = _database;
    if (currentDatabase == null) return;
    await currentDatabase.close();
    _database = null;
  }

  Future<void> _createSchema(Database database, int version) async {
    final batch = database.batch();

    batch.execute('''
      CREATE TABLE crop_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        asset_path TEXT,
        is_available INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    batch.execute('''
      CREATE TABLE plots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop_type_id INTEGER NOT NULL,
        project_name TEXT NOT NULL,
        name TEXT NOT NULL,
        location TEXT,
        variety_code TEXT,
        variety_name TEXT,
        raised_bed_count INTEGER NOT NULL DEFAULT 1,
        area_size REAL,
        area_unit TEXT,
        planted_at TEXT,
        expected_harvest_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (crop_type_id) REFERENCES crop_types (id)
          ON UPDATE CASCADE ON DELETE RESTRICT
      )
    ''');

    batch.execute('''
      CREATE TABLE plant_rows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        plant_count INTEGER NOT NULL DEFAULT 0,
        planted_at TEXT,
        expected_harvest_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (plot_id) REFERENCES plots (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE plot_varieties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        variety_code TEXT NOT NULL,
        variety_name TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (plot_id, variety_code),
        FOREIGN KEY (plot_id) REFERENCES plots (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE raised_beds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        bed_number INTEGER NOT NULL,
        seedling_count INTEGER,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (plot_id, bed_number),
        FOREIGN KEY (plot_id) REFERENCES plots (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE raised_bed_varieties (
        raised_bed_id INTEGER NOT NULL,
        variety_code TEXT NOT NULL,
        variety_name TEXT NOT NULL,
        PRIMARY KEY (raised_bed_id, variety_code),
        FOREIGN KEY (raised_bed_id) REFERENCES raised_beds (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE farm_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        plant_row_id INTEGER,
        activity_type TEXT NOT NULL,
        control_method TEXT,
        product_name TEXT,
        scheduled_at TEXT NOT NULL,
        completed_at TEXT,
        status TEXT NOT NULL DEFAULT 'scheduled',
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (plot_id) REFERENCES plots (id)
          ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (plant_row_id) REFERENCES plant_rows (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE farm_activity_raised_beds (
        activity_id INTEGER NOT NULL,
        raised_bed_id INTEGER NOT NULL,
        PRIMARY KEY (activity_id, raised_bed_id),
        FOREIGN KEY (activity_id) REFERENCES farm_activities (id)
          ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (raised_bed_id) REFERENCES raised_beds (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE farm_activity_control_products (
        activity_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_detail TEXT NOT NULL,
        PRIMARY KEY (activity_id, product_name),
        FOREIGN KEY (activity_id) REFERENCES farm_activities (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE disease_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        plant_row_id INTEGER,
        disease_name TEXT,
        symptoms TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'reported',
        reported_at TEXT NOT NULL,
        resolved_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (plot_id) REFERENCES plots (id)
          ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (plant_row_id) REFERENCES plant_rows (id)
          ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE app_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    batch.execute('''
      CREATE TABLE task_notification_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notification_id INTEGER NOT NULL,
        task_id INTEGER NOT NULL,
        plot_id INTEGER NOT NULL,
        task_type TEXT NOT NULL,
        crop_code TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        reminder_at TEXT NOT NULL,
        task_scheduled_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        canceled_at TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (task_id, reminder_at)
      )
    ''');

    batch.execute(
      'CREATE INDEX index_plant_rows_plot_id ON plant_rows (plot_id)',
    );
    batch.execute(
      'CREATE INDEX index_plot_varieties_plot_id ON plot_varieties (plot_id)',
    );
    batch.execute(
      'CREATE INDEX index_raised_beds_plot_id ON raised_beds (plot_id)',
    );
    batch.execute(
      'CREATE INDEX index_farm_activities_plot_id '
      'ON farm_activities (plot_id)',
    );
    batch.execute(
      'CREATE INDEX index_farm_activities_scheduled_at '
      'ON farm_activities (scheduled_at)',
    );
    batch.execute(
      'CREATE INDEX index_farm_activity_raised_beds_raised_bed_id '
      'ON farm_activity_raised_beds (raised_bed_id)',
    );
    batch.execute(
      'CREATE INDEX index_disease_reports_plot_id '
      'ON disease_reports (plot_id)',
    );
    batch.execute(
      'CREATE INDEX index_task_notification_history_reminder_at '
      'ON task_notification_history (reminder_at)',
    );
    batch.execute(
      'CREATE INDEX index_task_notification_history_task_id '
      'ON task_notification_history (task_id)',
    );
    batch.execute(
      'CREATE INDEX index_task_notification_history_read_reminder_at '
      'ON task_notification_history (is_read, reminder_at)',
    );

    const cropTypes = <Map<String, Object?>>[
      {
        'code': 'pineapple',
        'display_name': 'Nanas',
        'asset_path': 'assets/images/seeds/pineapple_fruit.png',
        'is_available': 1,
      },
      {
        'code': 'coconut',
        'display_name': 'Kelapa',
        'asset_path': 'assets/images/seeds/coconut_fruit.png',
        'is_available': 1,
      },
      {
        'code': 'banana',
        'display_name': 'Pisang',
        'asset_path': 'assets/images/seeds/banana_fruit.png',
        'is_available': 1,
      },
      {
        'code': 'oil_palm',
        'display_name': 'Sawit',
        'asset_path': 'assets/images/seeds/oil_palm_fruit_bunch.png',
        'is_available': 1,
      },
      {
        'code': 'rubber_tree',
        'display_name': 'Getah',
        'asset_path': 'assets/images/seeds/rubber_seeds.png',
        'is_available': 1,
      },
      {
        'code': 'ginger',
        'display_name': 'Halia',
        'asset_path': 'assets/images/seeds/ginger_rhizome.png',
        'is_available': 1,
      },
      {
        'code': 'rice',
        'display_name': 'Padi',
        'asset_path': 'assets/images/seeds/rice_stalks.png',
        'is_available': 1,
      },
      {
        'code': 'torch_ginger',
        'display_name': 'Bunga Kantan',
        'asset_path': 'assets/images/seeds/torch_ginger_buds.png',
        'is_available': 1,
      },
    ];

    for (final cropType in [...cropTypes, ..._additionalCropTypes]) {
      batch.insert('crop_types', cropType);
    }

    await batch.commit(noResult: true);
    await _ensureSyncTracking(database);
  }

  Future<void> _upgradeSchema(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      const assetPaths = <String, String>{
        'ginger': 'assets/images/seeds/ginger_rhizome.png',
        'rice': 'assets/images/seeds/rice_stalks.png',
        'torch_ginger': 'assets/images/seeds/torch_ginger_buds.png',
      };

      final batch = database.batch();
      for (final entry in assetPaths.entries) {
        batch.update(
          'crop_types',
          {
            'asset_path': entry.value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'code = ?',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    }

    if (oldVersion < 3) {
      final batch = database.batch();
      batch.execute(
        "ALTER TABLE plots ADD COLUMN project_name TEXT NOT NULL DEFAULT ''",
      );
      batch.execute('ALTER TABLE plots ADD COLUMN variety_code TEXT');
      batch.execute('ALTER TABLE plots ADD COLUMN variety_name TEXT');
      batch.execute(
        'ALTER TABLE plots ADD COLUMN raised_bed_count INTEGER NOT NULL DEFAULT 1',
      );
      await batch.commit(noResult: true);
    }

    if (oldVersion < 4) {
      await database.execute('''
        CREATE TABLE plot_varieties (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plot_id INTEGER NOT NULL,
          variety_code TEXT NOT NULL,
          variety_name TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          UNIQUE (plot_id, variety_code),
          FOREIGN KEY (plot_id) REFERENCES plots (id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''');
      await database.execute(
        'CREATE INDEX index_plot_varieties_plot_id '
        'ON plot_varieties (plot_id)',
      );
      await database.execute('''
        INSERT OR IGNORE INTO plot_varieties (
          plot_id,
          variety_code,
          variety_name
        )
        SELECT id, variety_code, variety_name
        FROM plots
        WHERE variety_code IS NOT NULL AND variety_name IS NOT NULL
      ''');
    }

    if (oldVersion < 5) {
      await database.update(
        'crop_types',
        {
          'is_available': 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'code = ?',
        whereArgs: ['coconut'],
      );
    }

    if (oldVersion < 6) {
      await database.execute('''
        CREATE TABLE raised_beds (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plot_id INTEGER NOT NULL,
          bed_number INTEGER NOT NULL,
          seedling_count INTEGER,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          UNIQUE (plot_id, bed_number),
          FOREIGN KEY (plot_id) REFERENCES plots (id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''');
      await database.execute(
        'CREATE INDEX index_raised_beds_plot_id ON raised_beds (plot_id)',
      );

      final plots = await database.query(
        'plots',
        columns: ['id', 'raised_bed_count'],
      );
      final batch = database.batch();
      for (final plot in plots) {
        final plotId = plot['id'] as int;
        final raisedBedCount = plot['raised_bed_count'] as int;
        for (var bedNumber = 1; bedNumber <= raisedBedCount; bedNumber++) {
          batch.insert('raised_beds', {
            'plot_id': plotId,
            'bed_number': bedNumber,
          });
        }
      }
      await batch.commit(noResult: true);
    }

    if (oldVersion < 7) {
      await database.execute('''
        CREATE TABLE farm_activity_raised_beds (
          activity_id INTEGER NOT NULL,
          raised_bed_id INTEGER NOT NULL,
          PRIMARY KEY (activity_id, raised_bed_id),
          FOREIGN KEY (activity_id) REFERENCES farm_activities (id)
            ON UPDATE CASCADE ON DELETE CASCADE,
          FOREIGN KEY (raised_bed_id) REFERENCES raised_beds (id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''');
      await database.execute(
        'CREATE INDEX index_farm_activity_raised_beds_raised_bed_id '
        'ON farm_activity_raised_beds (raised_bed_id)',
      );
    }

    if (oldVersion < 8) {
      const seedAssetPaths = <String, String>{
        'pineapple': 'assets/images/seeds/pineapple_fruit.png',
        'coconut': 'assets/images/seeds/coconut_fruit.png',
        'banana': 'assets/images/seeds/banana_fruit.png',
        'oil_palm': 'assets/images/seeds/oil_palm_fruit_bunch.png',
        'rubber_tree': 'assets/images/seeds/rubber_seeds.png',
        'ginger': 'assets/images/seeds/ginger_rhizome.png',
        'rice': 'assets/images/seeds/rice_stalks.png',
        'torch_ginger': 'assets/images/seeds/torch_ginger_buds.png',
      };
      final batch = database.batch();
      for (final entry in seedAssetPaths.entries) {
        batch.update(
          'crop_types',
          {
            'asset_path': entry.value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'code = ?',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    }

    if (oldVersion < 9) {
      await database.execute(
        'ALTER TABLE farm_activities ADD COLUMN control_method TEXT',
      );
    }

    if (oldVersion < 10) {
      await database.execute('''
        CREATE TABLE farm_activity_control_products (
          activity_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          product_detail TEXT NOT NULL,
          PRIMARY KEY (activity_id, product_name),
          FOREIGN KEY (activity_id) REFERENCES farm_activities (id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 11) {
      await database.execute('''
        CREATE TABLE raised_bed_varieties (
          raised_bed_id INTEGER NOT NULL,
          variety_code TEXT NOT NULL,
          variety_name TEXT NOT NULL,
          PRIMARY KEY (raised_bed_id, variety_code),
          FOREIGN KEY (raised_bed_id) REFERENCES raised_beds (id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 12) {
      final settingRows = await database.query(
        'app_settings',
        columns: ['setting_key', 'setting_value'],
        where: 'setting_key IN (?, ?)',
        whereArgs: ['task_start_hour', 'task_start_minute'],
      );
      final settings = {
        for (final row in settingRows)
          row['setting_key'] as String: row['setting_value'] as String,
      };
      final legacyHour = (int.tryParse(settings['task_start_hour'] ?? '') ?? 7)
          .clamp(0, 23);
      final legacyMinute =
          (int.tryParse(settings['task_start_minute'] ?? '') ?? 30).clamp(
            0,
            59,
          );
      final activities = await database.query(
        'farm_activities',
        columns: ['id', 'scheduled_at'],
      );
      final batch = database.batch();
      for (final activity in activities) {
        final storedValue = activity['scheduled_at'] as String;
        final scheduledAt = DateTime.parse(storedValue).toLocal();
        if (scheduledAt.hour != 0 || scheduledAt.minute != 0) continue;
        final migrated = DateTime(
          scheduledAt.year,
          scheduledAt.month,
          scheduledAt.day,
          legacyHour,
          legacyMinute,
        );
        batch.update(
          'farm_activities',
          {'scheduled_at': migrated.toUtc().toIso8601String()},
          where: 'id = ?',
          whereArgs: [activity['id']],
        );
      }
      batch.delete(
        'app_settings',
        where: 'setting_key IN (?, ?)',
        whereArgs: ['task_start_hour', 'task_start_minute'],
      );
      await batch.commit(noResult: true);
    }

    if (oldVersion < 13) {
      await database.execute('''
        CREATE TABLE IF NOT EXISTS task_notification_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          notification_id INTEGER NOT NULL,
          task_id INTEGER NOT NULL,
          plot_id INTEGER NOT NULL,
          task_type TEXT NOT NULL,
          crop_code TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          reminder_at TEXT NOT NULL,
          task_scheduled_at TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          canceled_at TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          UNIQUE (task_id, reminder_at)
        )
      ''');
      await database.execute(
        'CREATE INDEX IF NOT EXISTS '
        'index_task_notification_history_reminder_at '
        'ON task_notification_history (reminder_at)',
      );
      await database.execute(
        'CREATE INDEX IF NOT EXISTS index_task_notification_history_task_id '
        'ON task_notification_history (task_id)',
      );
    }

    if (oldVersion < 14) {
      await _ensureTaskNotificationReadColumn(database);
      await database.execute(
        'CREATE INDEX IF NOT EXISTS '
        'index_task_notification_history_read_reminder_at '
        'ON task_notification_history (is_read, reminder_at)',
      );
    }

    if (oldVersion < 15) {
      await _ensureSyncTracking(database);
    }

    if (oldVersion < 16) {
      await database.update(
        'crop_types',
        {'is_available': 1},
        where: 'code IN (?, ?, ?, ?)',
        whereArgs: ['banana', 'oil_palm', 'rubber_tree', 'ginger'],
      );
    }
    if (oldVersion < 17) {
      await database.update(
        'crop_types',
        {'is_available': 1},
        where: 'code IN (?, ?)',
        whereArgs: ['rice', 'torch_ginger'],
      );
    }
    if (oldVersion < 18) {
      final batch = database.batch();
      for (final crop in _additionalCropTypes) {
        // Ignore existing rows, then update metadata without replacing IDs.
        batch.insert(
          'crop_types',
          crop,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        batch.update(
          'crop_types',
          crop,
          where: 'code = ?',
          whereArgs: [crop['code']],
        );
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _ensureSyncTracking(Database database) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await database.insert('app_settings', {
      'setting_key': '_sync_local_changed_at',
      'setting_value': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await database.insert('app_settings', {
      'setting_key': '_sync_applying_remote',
      'setting_value': '0',
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    for (final table in syncableTableNames) {
      for (final operation in const ['INSERT', 'UPDATE', 'DELETE']) {
        final triggerName = 'track_sync_${table}_${operation.toLowerCase()}';
        await database.execute('''
          CREATE TRIGGER IF NOT EXISTS $triggerName
          AFTER $operation ON $table
          WHEN COALESCE(
            (
              SELECT setting_value
              FROM app_settings
              WHERE setting_key = '_sync_applying_remote'
            ),
            '0'
          ) != '1'
          BEGIN
            INSERT OR REPLACE INTO app_settings (
              setting_key,
              setting_value,
              updated_at
            ) VALUES (
              '_sync_local_changed_at',
              strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
              strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
            );
          END
        ''');
      }
    }
  }
}
