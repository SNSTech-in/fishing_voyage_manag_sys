import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:fishing_voyage_manag_sys/utiles/ports_utils.dart';
import 'package:fishing_voyage_manag_sys/services/api_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 40;

  void resetConnection() {
    try {
      _database?.close();
    } catch (_) {}
    _database = null;
  }

  /// Always returns a live database. Reopens if closed.
  Future<Database> get database async {
    // Always verify the connection is alive
    if (_database != null) {
      try {
        if (_database!.isOpen) {
          // Quick health check – if this throws, the DB is dead
          await _database!.rawQuery('SELECT 1');
          return _database!;
        }
      } catch (_) {
        // Connection is dead – fall through to (re)open
        _database = null;
      }
    }

    final String path = join(await getDatabasesPath(), 'boat_owner.db');
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _database!.rawQuery('PRAGMA busy_timeout = 5000');

    // ⭐ ALWAYS ensure these tables exist, regardless of the DB version
    await _ensureQueueTables(_database!);

    return _database!;
  }

  /// Universal retry wrapper – retries on database_closed
  Future<T> runWithRetry<T>(Future<T> Function(Database db) action) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final db = await database;
        return await action(db);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('database_closed') && attempt < 2) {
          debugPrint('🔄 DB closed – reopening (attempt ${attempt + 1})');
          _database = null; // Force fresh reopen on next iteration
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Database operation failed after retries');
  }

  // ============================================================
  // ON CREATE (full schema)
  // ============================================================

  Future<void> _onCreate(Database db, int version) async {
    // USER SESSION
    await db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mobile_no TEXT NOT NULL,
        setup_token TEXT,
        access_token TEXT,
        refresh_token TEXT,
        token_type TEXT,
        expires_in INTEGER,
        profile_data INTEGER DEFAULT 0,
        owner_id INTEGER,
        user_name TEXT,
        role TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // BOAT OWNER
    await db.execute('''
      CREATE TABLE boat_owner (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_name TEXT NOT NULL,
        address TEXT NOT NULL,
        aadhaar TEXT NOT NULL,
        mobile TEXT NOT NULL,
        home_port_id TEXT,
        home_port_name TEXT,
        photo_path TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // BOATS
    await db.execute('''
      CREATE TABLE boats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL,
        boat_name TEXT NOT NULL,
        registration_number TEXT NOT NULL,
        length TEXT NOT NULL,
        engine TEXT NOT NULL,
        home_port TEXT NOT NULL,
        is_selected INTEGER DEFAULT 0,
        FOREIGN KEY (owner_id) REFERENCES boat_owner (id)
      )
    ''');

    // BOAT SELECTION
    await db.execute('''
      CREATE TABLE boat_selection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        boat_id INTEGER UNIQUE NOT NULL,
        boat_name TEXT NOT NULL,
        registration_number TEXT NOT NULL,
        is_selected INTEGER DEFAULT 1,
        selected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // VOYAGES
    await db.execute('''
      CREATE TABLE voyages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        boat_owner_id INTEGER,
        boat_id INTEGER,
        boat_name TEXT,
        boat_reg_no TEXT,
        boat_number TEXT,
        reference_no TEXT,
        fishing_license TEXT,
        fishing_license_no TEXT,
        departure_port TEXT,
        destination_port TEXT,
        destination_ports_text TEXT,
        voyage_number TEXT,
        voyage_date TEXT,
        start_date TEXT,
        voyage_start_date TEXT,
        trip_start_datetime TEXT,
        actual_departure_time TEXT,
        expected_return_date TEXT,
        return_date TEXT,
        voyage_return_date TEXT,
        actual_return_date TEXT,
        trip_end_datetime TEXT,
        end_date TIMESTAMP,
        fresh_water TEXT,
        diesel TEXT,
        life_jackets INTEGER DEFAULT 0,
        life_boys INTEGER DEFAULT 0,
        communication_devices INTEGER DEFAULT 0,
        emergency_name TEXT,
        emergency_mobile TEXT,
        emergency_contact TEXT,
        captain_name TEXT,
        crew_count INTEGER DEFAULT 0,
        total_crew_count INTEGER DEFAULT 0,
        crew_names TEXT,
        crew_names_json TEXT,
        crew_details TEXT,
        all_crew_returned INTEGER DEFAULT 0,
        returned_crew_ids TEXT,
        voyage_slot INTEGER DEFAULT 1,
        status TEXT DEFAULT 'applied',
        derived_status TEXT,
        trip_status TEXT DEFAULT 'PENDING',
        btn_status TEXT,
        fish_catch_details TEXT,
        total_fish_weight_kg REAL DEFAULT 0.0,
        travelled_route TEXT,
        other_state_count INTEGER DEFAULT 0,
        illegal_activity_count INTEGER DEFAULT 0,
        citing_count INTEGER DEFAULT 0,
        sos_count INTEGER DEFAULT 0,
        notified_officer TEXT,
        previous_catch_submitted INTEGER DEFAULT 0,
        voyage_synced INTEGER DEFAULT 1,
        started_at TIMESTAMP,
        completed_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (boat_owner_id) REFERENCES boat_owner (id)
      )
    ''');

    // CREW MEMBERS
    await db.execute('''
      CREATE TABLE crew_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voyage_id INTEGER,
        crew_name TEXT,
        license_number TEXT,
        aadhaar TEXT,
        mobile TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (voyage_id) REFERENCES voyages (id) ON DELETE SET NULL
      )
    ''');

    // FISH CATCHES
    await db.execute('''
      CREATE TABLE fish_catches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voyage_id INTEGER NOT NULL,
        species TEXT NOT NULL,
        weight TEXT NOT NULL,
        total_catch TEXT NOT NULL,
        returned_fuel TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (voyage_id) REFERENCES voyages (id)
      )
    ''');

    // BOAT LOCATIONS
    await db.execute('''
      CREATE TABLE boat_locations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voyage_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        intimation_id INTEGER,
        voyage_no TEXT,
        ping_date_time TEXT,
        synced_at TEXT,
        UNIQUE(voyage_id, latitude, longitude, timestamp) ON CONFLICT IGNORE
      )
    ''');

    // LOCATION POINTS (Alias/Standard)
    await db.execute('''
      CREATE TABLE location_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intimation_id INTEGER,
        voyage_id INTEGER,
        voyage_no TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        ping_date_time TEXT,
        synced INTEGER DEFAULT 0,
        synced_at TEXT,
        UNIQUE(voyage_id, latitude, longitude, timestamp) ON CONFLICT IGNORE
      );
    ''');

    // SOS EVENTS
    await db.execute('''
      CREATE TABLE sos_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voyage_id INTEGER NOT NULL,
        intimation_id INTEGER,
        sos_type TEXT,
        severity TEXT,
        description TEXT,
        latitude REAL,
        longitude REAL,
        location_source TEXT,
        sos_datetime TEXT,
        synced INTEGER DEFAULT 0,
        synced_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // CITING EVENTS
    await db.execute('''
      CREATE TABLE citing_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voyage_id INTEGER NOT NULL,
        intimation_id INTEGER,
        citing_type TEXT,
        count INTEGER,
        remarks TEXT,
        latitude REAL,
        longitude REAL,
        citing_datetime TEXT,
        synced INTEGER DEFAULT 0,
        synced_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // LEGACY TABLES & DATA
    await db.execute('''
      CREATE TABLE IF NOT EXISTS officers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        officer_name TEXT,
        assigned_port TEXT,
        mobile_number TEXT,
        official_email TEXT,
        password TEXT,
        status TEXT,
        role TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_ports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        port_name TEXT NOT NULL UNIQUE,
        latitude REAL,
        longitude REAL,
        is_custom INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default Lakshadweep islands
    for (var entry in PortsUtils.defaultPortCoordinates.entries) {
      try {
        await db.insert('custom_ports', {
          'port_name': entry.key,
          'latitude': entry.value['lat'],
          'longitude': entry.value['lng'],
          'is_custom': 0,
        });
      } catch (e) {}
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_session(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_logged_in INTEGER DEFAULT 0,
        user_id INTEGER,
        phone_number TEXT,
        user_type TEXT DEFAULT 'boat_owner',
        login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.insert('active_session', {'id': 1, 'is_logged_in': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from $oldVersion to $newVersion');

    // 1. Ensure all tables exist (without dropping)
    await _ensureTablesExist(db);

    // 2. Add missing columns for each version
    if (oldVersion < 27) {
      // Voyages table columns
      await _addColumnIfMissing(db, 'voyages', 'reference_no TEXT');
      await _addColumnIfMissing(db, 'voyages', 'boat_name TEXT');
      await _addColumnIfMissing(db, 'voyages', 'boat_reg_no TEXT');
      await _addColumnIfMissing(db, 'voyages', 'derived_status TEXT DEFAULT "UNKNOWN"');
      await _addColumnIfMissing(db, 'voyages', 'destination_ports_text TEXT');
      await _addColumnIfMissing(db, 'voyages', 'total_crew_count INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'voyages', 'voyage_start_date TEXT');
      await _addColumnIfMissing(db, 'voyages', 'voyage_return_date TEXT');
      await _addColumnIfMissing(db, 'voyages', 'total_fish_weight_kg REAL DEFAULT 0.0');
      await _addColumnIfMissing(db, 'voyages', 'sos_count INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'voyages', 'citing_count INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'voyages', 'btn_status TEXT');
      await _addColumnIfMissing(db, 'voyages', 'crew_names_json TEXT');
      await _addColumnIfMissing(db, 'voyages', 'boat_id INTEGER');
      await _addColumnIfMissing(db, 'voyages', 'boat_number TEXT');
      await _addColumnIfMissing(db, 'voyages', 'fishing_license_no TEXT');
      await _addColumnIfMissing(db, 'voyages', 'destination_port TEXT');
      await _addColumnIfMissing(db, 'voyages', 'start_date TEXT');
      await _addColumnIfMissing(db, 'voyages', 'return_date TEXT');
      await _addColumnIfMissing(db, 'voyages', 'fresh_water TEXT');
      await _addColumnIfMissing(db, 'voyages', 'diesel TEXT');
      await _addColumnIfMissing(db, 'voyages', 'life_jackets TEXT');
      await _addColumnIfMissing(db, 'voyages', 'life_buoys TEXT');
      await _addColumnIfMissing(db, 'voyages', 'communication_devices INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'voyages', 'emergency_name TEXT');
      await _addColumnIfMissing(db, 'voyages', 'emergency_mobile TEXT');
      await _addColumnIfMissing(db, 'voyages', 'status TEXT DEFAULT "pending"');

      // Add any other missing columns for other tables if needed
      await _addColumnIfMissing(db, 'boat_locations', 'voyage_id INTEGER NOT NULL');
      await _addColumnIfMissing(db, 'boat_locations', 'latitude REAL NOT NULL');
      await _addColumnIfMissing(db, 'boat_locations', 'longitude REAL NOT NULL');
      await _addColumnIfMissing(db, 'boat_locations', 'timestamp TEXT NOT NULL');
      await _addColumnIfMissing(db, 'boat_locations', 'synced INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'boat_locations', 'created_at TEXT DEFAULT CURRENT_TIMESTAMP');

      // Ensure other tables have required columns (add as needed)
      print('✅ All columns added (or already present) for version 27');
    }

    // For future versions, add more blocks:
    if (oldVersion < 28) {
      try {
        // Check if column exists
        final columns = await db.rawQuery("PRAGMA table_info(voyages)");
        bool hasLifeBuoys = columns.any((col) => col['name'] == 'life_buoys');
        if (hasLifeBuoys) {
          await db.execute('ALTER TABLE voyages RENAME COLUMN life_buoys TO life_boys');
          print('✅ Renamed column life_buoys to life_boys');
        }
      } catch (e) {
        print('❌ Error renaming column: $e');
      }
    }

    if (oldVersion < 29) {
      try {
        final columns = await db.rawQuery("PRAGMA table_info(voyages)");

        // 1. life_boys -> life_buoys
        bool hasLifeBoys = columns.any((col) => col['name'] == 'life_boys');
        if (hasLifeBoys) {
          await db.execute('ALTER TABLE voyages RENAME COLUMN life_boys TO life_buoys');
          print('✅ Renamed column life_boys to life_buoys');
        }

        // 2. life_jacket -> life_jackets
        bool hasLifeJacket = columns.any((col) => col['name'] == 'life_jacket');
        if (hasLifeJacket) {
          await db.execute('ALTER TABLE voyages RENAME COLUMN life_jacket TO life_jackets');
          print('✅ Renamed column life_jacket to life_jackets');
        }
      } catch (e) {
        print('❌ Error in version 29 upgrade: $e');
      }
    }

    if (oldVersion < 30) {
      try {
        final columns = await db.rawQuery("PRAGMA table_info(voyages)");
        bool hasLifeBuoys = columns.any((col) => col['name'] == 'life_buoys');
        if (hasLifeBuoys) {
          await db.execute('ALTER TABLE voyages RENAME COLUMN life_buoys TO life_boys');
          print('✅ Renamed column life_buoys to life_boys (Version 30)');
        }
      } catch (e) {
        print('❌ Error in version 30 upgrade: $e');
      }
    }

    if (oldVersion < 31) {
      try {
        // Add missing columns to voyages table
        await db.execute('ALTER TABLE voyages ADD COLUMN life_jackets INTEGER DEFAULT 0');
        print('✅ Added missing columns to voyages table');
      } catch (e) {
        print('⚠️ Error adding columns: $e');
      }
    }

    if (oldVersion < 32) {
      try {
        final columns = await db.rawQuery("PRAGMA table_info(voyages)");
        bool hasLifeBuoys = columns.any((col) => col['name'] == 'life_buoys');
        if (hasLifeBuoys) {
          await db.execute('ALTER TABLE voyages RENAME COLUMN life_buoys TO life_boys');
          print('✅ Renamed column life_buoys to life_boys (Version 32)');
        }
      } catch (e) {
        print('❌ Error in version 32 upgrade: $e');
      }
    }

    if (oldVersion < 33) {
      try {
        // Rename life_jacket to life_jackets
        final columns = await db.rawQuery("PRAGMA table_info(voyages)");
        bool hasLifeJacket = columns.any((col) => col['name'] == 'life_jacket');
        if (hasLifeJacket) {
          await db.execute('ALTER TABLE voyages RENAME COLUMN life_jacket TO life_jackets');
          print('✅ Renamed column life_jacket to life_jackets (Version 33)');
        }
      } catch (e) {
        print('⚠️ Error renaming column: $e');
      }
    }

    if (oldVersion < 34) {
      try {
        print('🚀 Starting robust migration for version 34 (Recreating voyages table)...');
        // Step 1: Rename the old table
        await db.execute('ALTER TABLE voyages RENAME TO voyages_old');

        // Step 2: Create the new table with the correct schema
        await db.execute('''
          CREATE TABLE voyages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            boat_owner_id INTEGER,
            boat_id INTEGER,
            boat_name TEXT,
            boat_reg_no TEXT,
            boat_number TEXT,
            reference_no TEXT,
            fishing_license TEXT,
            fishing_license_no TEXT,
            departure_port TEXT,
            destination_port TEXT,
            destination_ports_text TEXT,
            voyage_number TEXT,
            voyage_date TEXT,
            start_date TEXT,
            voyage_start_date TEXT,
            trip_start_datetime TEXT,
            actual_departure_time TEXT,
            expected_return_date TEXT,
            return_date TEXT,
            voyage_return_date TEXT,
            actual_return_date TEXT,
            trip_end_datetime TEXT,
            end_date TIMESTAMP,
            fresh_water TEXT,
            diesel TEXT,
            life_jackets INTEGER DEFAULT 0,
            life_boys INTEGER DEFAULT 0,
            communication_devices INTEGER DEFAULT 0,
            emergency_name TEXT,
            emergency_mobile TEXT,
            emergency_contact TEXT,
            captain_name TEXT,
            crew_count INTEGER DEFAULT 0,
            total_crew_count INTEGER DEFAULT 0,
            crew_names TEXT,
            crew_names_json TEXT,
            crew_details TEXT,
            all_crew_returned INTEGER DEFAULT 0,
            returned_crew_ids TEXT,
            voyage_slot INTEGER DEFAULT 1,
            status TEXT DEFAULT 'applied',
            derived_status TEXT,
            trip_status TEXT DEFAULT 'PENDING',
            btn_status TEXT,
            fish_catch_details TEXT,
            total_fish_weight_kg REAL DEFAULT 0.0,
            travelled_route TEXT,
            other_state_count INTEGER DEFAULT 0,
            illegal_activity_count INTEGER DEFAULT 0,
            citing_count INTEGER DEFAULT 0,
            sos_count INTEGER DEFAULT 0,
            notified_officer TEXT,
            previous_catch_submitted INTEGER DEFAULT 0,
            voyage_synced INTEGER DEFAULT 1,
            started_at TIMESTAMP,
            completed_at TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (boat_owner_id) REFERENCES boat_owner (id)
          )
        ''');

        // Step 3: Copy data from old table to new table
        final List<Map<String, dynamic>> columnsInfo = await db.rawQuery("PRAGMA table_info(voyages_old)");
        final List<String> oldColumns = columnsInfo.map((c) => c['name'] as String).toList();

        final List<String> targetColumns = [
          'id', 'boat_id', 'boat_name', 'boat_reg_no', 'boat_number', 'reference_no',
          'fishing_license_no', 'destination_port', 'destination_ports_text',
          'start_date', 'voyage_start_date', 'trip_start_datetime', 'actual_departure_time',
          'return_date', 'voyage_return_date', 'actual_return_date', 'trip_end_datetime', 'end_date',
          'fresh_water', 'diesel', 'life_jackets', 'life_boys', 'communication_devices',
          'emergency_name', 'emergency_mobile', 'crew_names_json', 'total_crew_count',
          'all_crew_returned', 'voyage_slot', 'status', 'derived_status', 'trip_status', 'btn_status',
          'fish_catch_details', 'total_fish_weight_kg', 'travelled_route', 'other_state_count',
          'illegal_activity_count', 'citing_count', 'sos_count', 'notified_officer',
          'voyage_synced', 'started_at', 'completed_at', 'created_at'
        ];

        final List<String> commonColumns = targetColumns.where((col) => oldColumns.contains(col)).toList();

        if (commonColumns.isNotEmpty) {
          final String columnsStr = commonColumns.join(', ');
          await db.execute('INSERT INTO voyages ($columnsStr) SELECT $columnsStr FROM voyages_old');
          print('✅ Copied ${commonColumns.length} columns from voyages_old to voyages');
        }

        // Step 4: Drop the old table
        await db.execute('DROP TABLE voyages_old');
        print('✅ Successfully migrated voyages table to version 34');
      } catch (e) {
        print('❌ Error during version 34 migration: $e');
        try {
          final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='voyages_old'");
          if (tables.isNotEmpty) {
            await db.execute('DROP TABLE IF EXISTS voyages');
            await db.execute('ALTER TABLE voyages_old RENAME TO voyages');
            print('🔄 Recovered voyages table from backup');
          }
        } catch (_) {}
        rethrow;
      }
    }

    if (oldVersion < 36) {
      try {
        // 1. Update boat_locations table
        await _addColumnIfMissing(db, 'boat_locations', 'intimation_id INTEGER');
        await _addColumnIfMissing(db, 'boat_locations', 'voyage_no TEXT');
        await _addColumnIfMissing(db, 'boat_locations', 'ping_date_time TEXT');
        await _addColumnIfMissing(db, 'boat_locations', 'is_synced INTEGER DEFAULT 0');
        await _addColumnIfMissing(db, 'boat_locations', 'synced_at TEXT');

        // 2. Create location_points table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS location_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            intimation_id INTEGER,
            voyage_id INTEGER,
            voyage_no TEXT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT,
            ping_date_time TEXT,
            is_synced INTEGER DEFAULT 0,
            synced_at TEXT
          );
        ''');
        print('✅ Version 36 migration: boat_locations updated and location_points created');
      } catch (e) {
        print('⚠️ Error in version 36 migration: $e');
      }
    }

    if (oldVersion < 38) {
      try {
        print('🚀 Migrating location tables to add UNIQUE constraints...');

        // 1. Migrate boat_locations
        await db.execute('ALTER TABLE boat_locations RENAME TO boat_locations_old');
        await db.execute('''
          CREATE TABLE boat_locations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            voyage_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            intimation_id INTEGER,
            voyage_no TEXT,
            ping_date_time TEXT,
            is_synced INTEGER DEFAULT 0,
            synced_at TEXT,
            UNIQUE(voyage_id, latitude, longitude, timestamp) ON CONFLICT IGNORE
          )
        ''');
        await db.execute('''
          INSERT INTO boat_locations (id, voyage_id, latitude, longitude, timestamp, synced, created_at, intimation_id, voyage_no, ping_date_time, is_synced, synced_at)
          SELECT id, voyage_id, latitude, longitude, timestamp, synced, created_at, intimation_id, voyage_no, ping_date_time, is_synced, synced_at FROM boat_locations_old
        ''');
        await db.execute('DROP TABLE boat_locations_old');

        // 2. Migrate location_points
        await db.execute('ALTER TABLE location_points RENAME TO location_points_old');
        await db.execute('''
          CREATE TABLE location_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            intimation_id INTEGER,
            voyage_id INTEGER,
            voyage_no TEXT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT,
            ping_date_time TEXT,
            is_synced INTEGER DEFAULT 0,
            synced_at TEXT,
            UNIQUE(voyage_id, latitude, longitude, timestamp) ON CONFLICT IGNORE
          )
        ''');
        await db.execute('''
          INSERT INTO location_points (id, intimation_id, voyage_id, voyage_no, latitude, longitude, timestamp, ping_date_time, is_synced, synced_at)
          SELECT id, intimation_id, voyage_id, voyage_no, latitude, longitude, timestamp, ping_date_time, is_synced, synced_at FROM location_points_old
        ''');
        await db.execute('DROP TABLE location_points_old');

        print('✅ Version 38 migration: UNIQUE constraints added to location tables');
      } catch (e) {
        print('❌ Version 38 migration failed: $e');
      }
    }

    if (oldVersion < 40) {
      try {
        // ---- migration: ensure `synced` exists on all queues ----
        final lpCols = await db.rawQuery('PRAGMA table_info(location_points)');
        final lpNames = lpCols.map((c) => c['name'] as String).toSet();

        if (!lpNames.contains('synced')) {
          await db.execute(
              'ALTER TABLE location_points ADD COLUMN synced INTEGER NOT NULL DEFAULT 0');
        }

        for (final t in ['sos_queue', 'citing_queue']) {
          final c = await db.rawQuery('PRAGMA table_info($t)');
          final n = c.map((x) => x['name'] as String).toSet();
          if (!n.contains('synced')) {
            await db.execute(
                'ALTER TABLE $t ADD COLUMN synced INTEGER NOT NULL DEFAULT 0');
          }
        }

        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_location_synced ON location_points(synced)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sos_synced ON sos_queue(synced)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_citing_synced ON citing_queue(synced)');
      } catch (e) {
        print('⚠️ Version 40 migration warning: $e');
      }
    }
  }

  Future<void> _ensureTablesExist(Database db) async {
    // Check if boat_locations exists; if not, create it
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='boat_locations'"
    );
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE boat_locations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          voyage_id INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      print('✅ Created boat_locations table');
    }

    // Similarly, ensure voyages table exists
    final voyages = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='voyages'"
    );
    if (voyages.isEmpty) {
      await db.execute('''
        CREATE TABLE voyages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          boat_owner_id INTEGER,
          boat_id INTEGER,
          boat_name TEXT,
          boat_reg_no TEXT,
          boat_number TEXT,
          reference_no TEXT,
          fishing_license TEXT,
          fishing_license_no TEXT,
          departure_port TEXT,
          destination_port TEXT,
          destination_ports_text TEXT,
          voyage_number TEXT,
          voyage_date TEXT,
          start_date TEXT,
          voyage_start_date TEXT,
          trip_start_datetime TEXT,
          actual_departure_time TEXT,
          expected_return_date TEXT,
          return_date TEXT,
          voyage_return_date TEXT,
          actual_return_date TEXT,
          trip_end_datetime TEXT,
          end_date TIMESTAMP,
          fresh_water TEXT,
          diesel TEXT,
          life_jackets INTEGER DEFAULT 0,
          life_boys INTEGER DEFAULT 0,
          communication_devices INTEGER DEFAULT 0,
          emergency_name TEXT,
          emergency_mobile TEXT,
          emergency_contact TEXT,
          captain_name TEXT,
          crew_count INTEGER DEFAULT 0,
          total_crew_count INTEGER DEFAULT 0,
          crew_names TEXT,
          crew_names_json TEXT,
          crew_details TEXT,
          all_crew_returned INTEGER DEFAULT 0,
          returned_crew_ids TEXT,
          voyage_slot INTEGER DEFAULT 1,
          status TEXT DEFAULT 'applied',
          derived_status TEXT,
          trip_status TEXT DEFAULT 'PENDING',
          btn_status TEXT,
          fish_catch_details TEXT,
          total_fish_weight_kg REAL DEFAULT 0.0,
          travelled_route TEXT,
          other_state_count INTEGER DEFAULT 0,
          illegal_activity_count INTEGER DEFAULT 0,
          citing_count INTEGER DEFAULT 0,
          sos_count INTEGER DEFAULT 0,
          notified_officer TEXT,
          previous_catch_submitted INTEGER DEFAULT 0,
          voyage_synced INTEGER DEFAULT 1,
          started_at TIMESTAMP,
          completed_at TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (boat_owner_id) REFERENCES boat_owner (id)
        )
      ''');
      print('✅ Created voyages table');
    }

    // USER SESSION
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        mobile_no TEXT NOT NULL,
        owner_id INTEGER,
        user_name TEXT,
        role TEXT
      )
    ''');
    // BOAT OWNER
    await db.execute('CREATE TABLE IF NOT EXISTS boat_owner (id INTEGER PRIMARY KEY AUTOINCREMENT, owner_name TEXT NOT NULL, address TEXT NOT NULL, aadhaar TEXT NOT NULL, mobile TEXT NOT NULL)');
    // BOATS
    await db.execute('CREATE TABLE IF NOT EXISTS boats (id INTEGER PRIMARY KEY AUTOINCREMENT, owner_id INTEGER NOT NULL, boat_name TEXT NOT NULL, registration_number TEXT NOT NULL, length TEXT NOT NULL, engine TEXT NOT NULL, home_port TEXT NOT NULL, is_selected INTEGER DEFAULT 0)');
    // BOAT SELECTION
    await db.execute('CREATE TABLE IF NOT EXISTS boat_selection (id INTEGER PRIMARY KEY AUTOINCREMENT, boat_id INTEGER UNIQUE NOT NULL, boat_name TEXT NOT NULL, registration_number TEXT NOT NULL, is_selected INTEGER DEFAULT 1, selected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    // CREW MEMBERS
    await db.execute('CREATE TABLE IF NOT EXISTS crew_members (id INTEGER PRIMARY KEY AUTOINCREMENT, voyage_id INTEGER, crew_name TEXT, license_number TEXT, aadhaar TEXT, mobile TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    // FISH CATCHES
    await db.execute('CREATE TABLE IF NOT EXISTS fish_catches (id INTEGER PRIMARY KEY AUTOINCREMENT, voyage_id INTEGER NOT NULL, species TEXT NOT NULL, weight TEXT NOT NULL, total_catch TEXT NOT NULL, returned_fuel TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    // SOS EVENTS
    await db.execute('CREATE TABLE IF NOT EXISTS sos_events (id INTEGER PRIMARY KEY AUTOINCREMENT, voyage_id INTEGER NOT NULL, created_at TEXT DEFAULT CURRENT_TIMESTAMP)');
    // CITING EVENTS
    await db.execute('CREATE TABLE IF NOT EXISTS citing_events (id INTEGER PRIMARY KEY AUTOINCREMENT, voyage_id INTEGER NOT NULL, created_at TEXT DEFAULT CURRENT_TIMESTAMP)');

    // OFFICERS
    await db.execute('CREATE TABLE IF NOT EXISTS officers (id INTEGER PRIMARY KEY AUTOINCREMENT, officer_name TEXT)');
    // CUSTOM PORTS
    await db.execute('CREATE TABLE IF NOT EXISTS custom_ports (id INTEGER PRIMARY KEY AUTOINCREMENT, port_name TEXT NOT NULL UNIQUE)');
    // ACTIVE SESSION
    await db.execute('CREATE TABLE IF NOT EXISTS active_session (id INTEGER PRIMARY KEY CHECK (id = 1), is_logged_in INTEGER DEFAULT 0)');
  }

  /// Idempotent — creates the queue tables if they don't already exist.
  /// Safe to call on every app start.
  Future<void> _ensureQueueTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sos_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intimation_id INTEGER,
        boat_reg_no TEXT,
        latitude REAL,
        longitude REAL,
        location_source TEXT,
        sos_datetime TEXT,
        remarks TEXT,
        description TEXT,
        sos_type TEXT,
        severity TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT
      )
    ''');

    await _addColumnIfMissing(db, 'sos_queue', 'description TEXT');
    await _addColumnIfMissing(db, 'sos_queue', 'boat_reg_no TEXT');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS citing_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intimation_id INTEGER,
        boat_reg_no TEXT,
        latitude REAL,
        longitude REAL,
        citing_type TEXT,
        citing_reason TEXT,
        citing_datetime TEXT,
        sighted_boat_count INTEGER,
        remarks TEXT,
        illegal_activity_type TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT
      )
    ''');

    await _addColumnIfMissing(db, 'citing_queue', 'boat_reg_no TEXT');

    debugPrint('✅ [DB] Queue tables ready');
  }

  Future<void> _addColumnIfMissing(
      Database db,
      String table,
      String columnDef,
      ) async {
    final columns = await db.rawQuery("PRAGMA table_info($table)");
    final colName = columnDef.split(' ').first;
    final exists = columns.any((col) => col['name'] == colName);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDef');
      print('✅ Added column $colName to $table');
    }
  }

  // ============================================================
  // CORE METHODS
  // ============================================================

  // ---- USER SESSION ----
  Future<bool> isUserLoggedIn() async {
    final session = await getUserSession();
    return session != null;
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    return await runWithRetry((db) async {
      final result = await db.query('user_session', limit: 1);
      if (result.isEmpty) return null;
      return Map<String, dynamic>.from(result.first);
    });
  }

  Future<void> insertUserSession(Map<String, dynamic> session) async {
    await runWithRetry((db) async {
      await db.delete('user_session');
      await db.insert('user_session', session);
    });
  }

  Future<void> updateUserSession(Map<String, dynamic> session) async {
    await runWithRetry((db) async {
      await db.update('user_session', session, where: 'id = ?', whereArgs: [session['id']]);
    });
  }

  Future<void> clearUserSession() async {
    await runWithRetry((db) async {
      await db.delete('user_session');
    });
  }

  Future<void> clearUserSessionOnly() async {
    await runWithRetry((db) async {
      await db.delete('user_session');
      await db.delete('boat_selection');
    });
    // Keep boat_owner, boats, voyages, crew_members, boat_locations, etc.
    print('✅ User session cleared, all voyage data retained.');
  }

  // ---- BOAT OWNER ----
  Future<int> insertBoatOwner(Map<String, dynamic> owner) async {
    return await runWithRetry((db) async {
      await db.delete('boat_owner');
      return await db.insert('boat_owner', owner);
    });
  }

  Future<Map<String, dynamic>?> getBoatOwner() async {
    return await runWithRetry((db) async {
      final result = await db.query('boat_owner', limit: 1);
      return result.isNotEmpty ? result.first : null;
    });
  }

  // ---- BOATS ----
  Future<int> insertBoat(Map<String, dynamic> boat) async {
    return await runWithRetry((db) async {
      return await db.insert('boats', boat);
    });
  }

  Future<List<Map<String, dynamic>>> getBoatsByOwnerId(int ownerId) async {
    return await runWithRetry((db) async {
      return await db.query('boats', where: 'owner_id = ?', whereArgs: [ownerId]);
    });
  }

  // ---- BOAT SELECTION ----
  Future<void> insertBoatSelection(Map<String, dynamic> boat) async {
    await runWithRetry((db) async {
      await db.insert(
        'boat_selection',
        {
          'boat_id': boat['boat_id'],
          'boat_name': boat['boat_name'] ?? 'Boat',
          'registration_number': boat['registration_number'] ?? 'N/A',
          'is_selected': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<Map<String, dynamic>>> getSelectedBoats() async {
    return await runWithRetry((db) async {
      return await db.query('boat_selection', where: 'is_selected = 1');
    });
  }

  Future<void> clearSelectedBoats() async {
    await runWithRetry((db) async {
      await db.delete('boat_selection');
    });
  }

  Future<bool> hasSelectedBoats() async {
    final boats = await getSelectedBoats();
    return boats.isNotEmpty;
  }

  // ---- VOYAGES ----
  Future<int> insertVoyage(Map<String, dynamic> voyage) async {
    return await runWithRetry((db) async {
      return await db.insert('voyages', voyage, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Map<String, dynamic>>> getAllVoyages() async {
    final List<Map<String, dynamic>> maps = await runWithRetry((db) async {
      return await db.query('voyages', orderBy: 'id DESC');
    });

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      // Map back intimation_id for dashboard
      map['intimation_id'] = map['id'];

      // Decode crew names if present
      if (map['crew_names_json'] != null) {
        try {
          map['crew_names'] = jsonDecode(map['crew_names_json']);
        } catch (e) {
          map['crew_names'] = [];
        }
      } else {
        map['crew_names'] = [];
      }

      return map;
    });
  }

  Future<List<Map<String, dynamic>>> getAllLocalVoyages() async {
    return await runWithRetry((db) async {
      return await db.query('voyages', orderBy: 'created_at DESC');
    });
  }

  Future<bool> syncVoyages({
    List<Map<String, dynamic>>? items,
    void Function(String errorMessage)? onError,
  }) async {
    try {
      List<Map<String, dynamic>> voyages;

      if (items == null) {
        // Use the robust fetch pattern if no items provided
        final api = ApiService();
        final List<dynamic> fetched = await api.fetchVoyages(onError: onError);
        if (fetched.isEmpty) {
          debugPrint('⚠️ No voyages to sync (empty list or error).');
          return false;
        }
        voyages = fetched.cast<Map<String, dynamic>>();
      } else {
        if (items.isEmpty) {
          debugPrint('⚠️ No voyages to sync (Empty list provided).');
          return false;
        }
        voyages = items;
      }

      return await runWithRetry((db) async {
        await db.transaction((txn) async {
          for (var item in voyages) {
            try {
              final int intimationId = item['intimation_id'] ?? 0;
              if (intimationId == 0) continue;

              final Map<String, dynamic> row = {
                'id': intimationId,
                'reference_no': item['reference_no'],
                'boat_name': item['boat_name'],
                'boat_reg_no': item['boat_reg_no'],
                'derived_status': item['derived_status'],
                'destination_ports_text': item['destination_ports_text'],
                'total_crew_count': item['total_crew_count'],
                'voyage_start_date': item['voyage_start_date'],
                'voyage_return_date': item['voyage_return_date'],
                'total_fish_weight_kg': item['total_fish_weight_kg'] ?? 0.0,
                'sos_count': item['sos_count'] ?? 0,
                'citing_count': item['citing_count'] ?? 0,
                'btn_status': item['btn_status'],
                'crew_names_json':
                item['crew_names'] != null ? jsonEncode(item['crew_names']) : null,
                'status':
                item['derived_status']?.toString().toLowerCase(), // fallback
              };

              // Also add required non-null fields from original schema with placeholders
              row['boat_id'] = item['boat_id'] ?? 0;
              row['boat_number'] = item['boat_reg_no'] ?? 'N/A';
              row['fishing_license_no'] = item['fishing_license_no'] ?? 'N/A';
              row['destination_port'] = item['destination_ports_text'] ?? 'N/A';
              row['start_date'] = item['voyage_start_date'] ?? 'N/A';
              row['return_date'] = item['voyage_return_date'] ?? 'N/A';
              row['fresh_water'] = item['fresh_water']?.toString() ?? '0';
              row['diesel'] = item['diesel']?.toString() ?? '0';
              row['life_jackets'] = int.tryParse(
                  (item['life_jackets'] ?? item['life_jacket'] ?? '0')
                      .toString()) ??
                  0;
              row['life_boys'] = int.tryParse(
                  (item['life_boys'] ?? item['life_buoys'] ?? '0').toString()) ??
                  0;
              row['communication_devices'] =
                  int.tryParse((item['communication_devices'] ?? '0').toString()) ?? 0;
              row['emergency_name'] = 'N/A';
              row['emergency_mobile'] = 'N/A';

              await txn.insert(
                'voyages',
                row,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            } catch (e) {
              // 🔑 Log and continue – one bad row doesn't kill the whole sync
              debugPrint('⚠️ Voyage insert failed for ${item['intimation_id']}: $e');
            }
          }
        });
        debugPrint('✅ Sync completed: ${voyages.length} voyages processed.');
        return true;
      });
    } catch (e, stack) {
      debugPrint('❌ Sync failed: $e\n$stack');
      _notifyError(onError, 'Failed to sync data to local database.');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getVoyagesByOwnerId(int ownerId) async {
    Database db = await database;
    return await db.query(
      'voyages',
      where: 'boat_owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getVoyageById(int voyageId) async {
    return await runWithRetry((db) async {
      final result = await db.query('voyages', where: 'id = ?', whereArgs: [voyageId]);
      return result.isNotEmpty ? result.first : null;
    });
  }

  Future<String?> getVoyageReferenceNo(int voyageId) async {
    final voyage = await getVoyageById(voyageId);
    return voyage?['reference_no']?.toString();
  }

  Future<int> updateVoyageStatus(int voyageId, String status) async {
    return await runWithRetry((db) async {
      final updates = <String, dynamic>{'status': status};

      if (status == 'active' || status == 'started' || status == 'AT SEA') {
        updates['status'] = 'active';
        updates['derived_status'] = 'AT SEA';
        updates['btn_status'] = 'End Trip';
        updates['trip_start_datetime'] = DateTime.now().toIso8601String();
      } else if (status == 'completed' || status == 'COMPLETED') {
        updates['status'] = 'completed';
        updates['derived_status'] = 'COMPLETED';
        updates['btn_status'] = null;
        updates['trip_end_datetime'] = DateTime.now().toIso8601String();
      }

      return await db.update('voyages', updates, where: 'id = ?', whereArgs: [voyageId]);
    });
  }

  Future<int> updateVoyageFishCatchDetails(int voyageId, String catchDetailsJson) async {
    return await runWithRetry((db) async {
      return await db.update(
        'voyages',
        {'fish_catch_details': catchDetailsJson},
        where: 'id = ?',
        whereArgs: [voyageId],
      );
    });
  }

  Future<void> updateVoyageSyncStatus(int voyageId, int synced) async {
    await runWithRetry((db) async {
      await db.update(
        'voyages',
        {'voyage_synced': synced},
        where: 'id = ?',
        whereArgs: [voyageId],
      );
    });
  }

  // ---- TRACKING ----
  Future<int> insertLocation(
    int voyageId,
    double latitude,
    double longitude, {
    String? voyageNo,
    String? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().toUtc().toIso8601String();

    String? refNo = voyageNo;
    if (refNo == null || refNo.isEmpty) {
      refNo = await getVoyageReferenceNo(voyageId);
    }

    final data = {
      'voyage_id': voyageId,
      'intimation_id': voyageId,
      'voyage_no': refNo ?? 'UNKNOWN',
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': ts,
      'ping_date_time': ts,
      'synced': 0,
    };

    return await runWithRetry((db) async {
      await db.insert('boat_locations', data, conflictAlgorithm: ConflictAlgorithm.ignore);
      return await db.insert('location_points', data, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    try {
      return await runWithRetry((db) =>
          db.query('location_points', where: 'synced = 0', orderBy: 'id ASC'));
    } catch (e) {
      print('⚠️ getUnsyncedLocations failed: $e');
      return [];
    }
  }

  Future<void> markLocationPermanentlyFailed(int id) async {
    try {
      await runWithRetry((db) async {
        await db.update(
          'location_points',
          {'synced': 2, 'synced_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
        await db.update(
          'boat_locations',
          {'synced': 2, 'synced_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      print('⚠️ markLocationPermanentlyFailed failed for $id: $e');
    }
  }

  Future<int> getUnsyncedLocationCount(int voyageId) async {
    try {
      return await runWithRetry((db) async {
        final result = await db.rawQuery(
          'SELECT COUNT(*) FROM location_points WHERE synced = 0 AND voyage_id = ?',
          [voyageId],
        );
        return Sqflite.firstIntValue(result) ?? 0;
      });
    } catch (e) {
      print('⚠️ getUnsyncedLocationCount failed: $e');
      return 0;
    }
  }

  Future<void> markLocationSynced(int id) async {
    try {
      await runWithRetry((db) async {
        await db.update(
          'location_points',
          {'synced': 1, 'synced_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
        await db.update(
          'boat_locations',
          {'synced': 1, 'synced_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      print('⚠️ markLocationSynced failed for $id: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLocationsForVoyage(int voyageId) async {
    return await runWithRetry((db) async {
      return await db.query('boat_locations', where: 'voyage_id = ?', whereArgs: [voyageId], orderBy: 'timestamp ASC');
    });
  }

  Future<Map<String, dynamic>?> getLastLocationPoint(int voyageId) async {
    return await runWithRetry((db) async {
      final result = await db.query(
        'boat_locations',
        where: 'voyage_id = ?',
        whereArgs: [voyageId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    });
  }

  Future<int> insertLocationPoint(Map<String, dynamic> data) async {
    try {
      return await runWithRetry((db) => db.insert(
        'location_points',
        data,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      ));
    } catch (e) {
      print('⚠️ insertLocationPoint failed: $e');
      return -1;
    }
  }

  Future<Map<String, dynamic>?> getActiveVoyage() async {
    return runWithRetry((db) async {
      final rows = await db.query(
        'voyages',
        where: "status IN ('ONGOING','ACTIVE','ongoing','active','AT SEA')",
        orderBy: 'id DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Map<String, dynamic>.from(rows.first);
    });
  }

  // ---- SOS & CITING QUEUE ----
  Future<int> queueSos(Map<String, dynamic> data) async {
    final db = await database;
    final Map<String, dynamic> row = Map<String, dynamic>.from(data);
    row['synced'] = 0;
    row['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('sos_queue', row);
  }

  Future<int> queueCiting(Map<String, dynamic> data) async {
    final db = await database;
    final Map<String, dynamic> row = Map<String, dynamic>.from(data);
    row['synced'] = 0;
    row['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('citing_queue', row);
  }

  Future<int> insertSosEvent(Map<String, dynamic> data) async {
    return await queueSos(data);
  }

  Future<int> insertCitingEvent(Map<String, dynamic> data) async {
    return await queueCiting(data);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSos() async {
    final db = await database;
    try {
      return await db.query(
        'sos_queue',
        where: 'synced = 0',
        orderBy: 'id ASC',
      );
    } catch (e) {
      debugPrint('🔎 [DB] getUnsyncedSos failed: $e');
      return [];
    }
  }

  Future<void> markSosSynced(int id) async {
    final db = await database;
    try {
      await db.update(
        'sos_queue',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('🔎 [DB] markSosSynced failed: $id, error: $e');
    }
  }

  Future<void> markSosPermanentlyFailed(int id) async {
    final db = await database;
    try {
      await db.update(
        'sos_queue',
        {'synced': 2}, // 2 = Skip/Permanent Fail
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('🔎 [DB] markSosPermanentlyFailed failed: $id, error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCiting() async {
    final db = await database;
    try {
      return await db.query(
        'citing_queue',
        where: 'synced = 0',
        orderBy: 'id ASC',
      );
    } catch (e) {
      debugPrint('🔎 [DB] getUnsyncedCiting failed: $e');
      return [];
    }
  }

  Future<void> markCitingSynced(int id) async {
    final db = await database;
    try {
      await db.update(
        'citing_queue',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('🔎 [DB] markCitingSynced failed: $id, error: $e');
    }
  }

  Future<void> markCitingPermanentlyFailed(int id) async {
    final db = await database;
    try {
      await db.update(
        'citing_queue',
        {'synced': 2}, // 2 = Permanent Fail / dead-letter
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('🔎 [DB] markCitingPermanentlyFailed failed: $id, error: $e');
    }
  }

  Future<int> insertSos({
    required int intimationId,
    required double latitude,
    required double longitude,
    required String sosDatetime,
    required String description,
    String sosType = 'OTHER',
    String severity = 'HIGH',
    String locationSource = 'GPS',
  }) async {
    final db = await database;
    return db.insert('sos_queue', {
      'intimation_id': intimationId,
      'latitude': latitude,
      'longitude': longitude,
      'sos_datetime': sosDatetime,
      'description': description,
      'remarks': description,
      'sos_type': sosType,
      'severity': severity,
      'location_source': locationSource,
      'synced': 0,
    });
  }

  Future<int> insertCiting({
    required int intimationId,
    required double latitude,
    required double longitude,
    required String citingDatetime,
    required String citingType,
    String? remarks,
    int? sightedBoatCount,
    String? illegalActivityType,
  }) async {
    final db = await database;
    return db.insert('citing_queue', {
      'intimation_id': intimationId,
      'latitude': latitude,
      'longitude': longitude,
      'citing_datetime': citingDatetime,
      'citing_reason': citingType,
      'citing_type': citingType,
      'remarks': remarks,
      'sighted_boat_count': sightedBoatCount,
      'illegal_activity_type': illegalActivityType,
      'synced': 0,
    });
  }

  Future<int> countUnsynced(String table) async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $table WHERE synced = 0');
    return (r.first['c'] as int?) ?? 0;
  }

  // ---- MAINTENANCE ----
  Future<void> clearAllData() async {
    await runWithRetry((db) async {
      await db.transaction((txn) async {
        await txn.delete('user_session');
        await txn.delete('boat_owner');
        await txn.delete('boats');
        await txn.delete('boat_selection');
        await txn.delete('voyages');
        await txn.delete('crew_members');
        await txn.delete('fish_catches');
        await txn.delete('boat_locations');
        await txn.delete('sos_events');
        await txn.delete('citing_events');
        await txn.delete('sos_queue');
        await txn.delete('citing_queue');
        // Legacy table
        await txn.update('active_session', {'is_logged_in': 0, 'user_id': null, 'phone_number': null}, where: 'id = 1');
      });
    });
  }

  Future<bool> isBoatAvailable(int boatId) async {
    return await runWithRetry((db) async {
      final result = await db.query(
        'voyages',
        where: 'boat_id = ? AND voyage_return_date > ?',
        whereArgs: [boatId, DateTime.now().toIso8601String()],
      );
      return result.isEmpty;
    });
  }

  Future<bool> isCrewAvailable(String identifier) async {
    return await runWithRetry((db) async {
      // Identifier can be mobile or aadhaar
      final result = await db.rawQuery('''
        SELECT id FROM crew_members 
        WHERE (mobile = ? OR aadhaar = ?) 
        AND voyage_id IN (
          SELECT id FROM voyages WHERE voyage_return_date > ?
        )
      ''', [identifier, identifier, DateTime.now().toIso8601String()]);
      return result.isEmpty;
    });
  }

  // ============================================================
  // ADDED METHODS FOR LEGACY SCREENS (Admin, Officer, Reports, etc.)
  // ============================================================

  // ---- Boat Owners (Legacy) ----
  Future<Map<String, dynamic>?> getBoatOwnerByMobile(String mobile) async {
    return await runWithRetry((db) async {
      final result = await db.query(
        'boat_owner',
        where: 'mobile = ?',
        whereArgs: [mobile],
      );
      return result.isNotEmpty ? result.first : null;
    });
  }

  Future<Map<String, dynamic>?> getBoatOwnerById(int id) async {
    return await runWithRetry((db) async {
      final result = await db.query(
        'boat_owner',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    });
  }

  Future<List<Map<String, dynamic>>> getAllBoatOwners() async {
    return await runWithRetry((db) async {
      return await db.query('boat_owner', orderBy: 'created_at DESC');
    });
  }

  Future<int> deleteBoatOwner(int id) async {
    return await runWithRetry((db) async {
      return await db.delete('boat_owner', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<bool> checkMobileExists(String mobile) async {
    return await runWithRetry((db) async {
      final result = await db.query('boat_owner', where: 'mobile = ?', whereArgs: [mobile]);
      return result.isNotEmpty;
    });
  }

  // ---- Session (Legacy) ----
  Future<void> saveLoginSession(int userId, String phone, {String userType = 'boat_owner'}) async {
    // We'll store in user_session table
    await runWithRetry((db) async {
      await db.delete('user_session'); // clear old
      await db.insert('user_session', {
        'mobile_no': phone,
        'owner_id': userId,
        'role': userType,
        'profile_data': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final session = await getUserSession();
    if (session == null) return null;
    final userId = session['owner_id'];
    if (userId == null) return null;
    return await getBoatOwnerById(userId);
  }

  // ---- Officers (Legacy) ----
  Future<int> addOfficer(Map<String, dynamic> officer) async {
    return await runWithRetry((db) async {
      // Check if officers table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='officers'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE officers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            officer_name TEXT NOT NULL,
            address TEXT,
            mobile_number TEXT UNIQUE,
            official_email TEXT UNIQUE,
            password TEXT,
            assigned_port TEXT,
            status TEXT DEFAULT 'active',
            role TEXT DEFAULT 'port_officer',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      }
      return await db.insert('officers', officer);
    });
  }

  Future<List<Map<String, dynamic>>> getAllOfficers() async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='officers'");
      if (tables.isEmpty) return [];
      return await db.query('officers', orderBy: 'created_at DESC');
    });
  }

  Future<Map<String, dynamic>?> getOfficerById(int id) async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='officers'");
      if (tables.isEmpty) return null;
      final result = await db.query('officers', where: 'id = ?', whereArgs: [id]);
      return result.isNotEmpty ? result.first : null;
    });
  }

  Future<int> deleteOfficer(int id) async {
    return await runWithRetry((db) async {
      return await db.delete('officers', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<bool> checkOfficerEmailExists(String email) async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='officers'");
      if (tables.isEmpty) return false;
      final result = await db.query('officers', where: 'official_email = ?', whereArgs: [email]);
      return result.isNotEmpty;
    });
  }

  Future<bool> checkOfficerMobileExists(String mobile) async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='officers'");
      if (tables.isEmpty) return false;
      final result = await db.query('officers', where: 'mobile_number = ?', whereArgs: [mobile]);
      return result.isNotEmpty;
    });
  }

  // ---- Ports (Legacy) ----
  Future<List<Map<String, dynamic>>> getAllCustomPorts() async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_ports'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE custom_ports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            port_name TEXT NOT NULL UNIQUE,
            latitude REAL,
            longitude REAL,
            is_custom INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      }
      return await db.query('custom_ports', orderBy: 'port_name ASC');
    });
  }

  Future<List<Map<String, dynamic>>> getOnlyCustomPorts() async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_ports'");
      if (tables.isEmpty) return [];
      return await db.query('custom_ports', where: 'is_custom = 1', orderBy: 'port_name ASC');
    });
  }

  Future<List<Map<String, dynamic>>> getDefaultPorts() async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_ports'");
      if (tables.isEmpty) return [];
      return await db.query('custom_ports', where: 'is_custom = 0', orderBy: 'port_name ASC');
    });
  }

  Future<List<String>> getAllPorts() async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_ports'");
      if (tables.isEmpty) return [];
      final result = await db.query('custom_ports', columns: ['port_name'], orderBy: 'port_name ASC');
      return result.map((row) => row['port_name'] as String).toList();
    });
  }

  Future<bool> checkPortExists(String portName) async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_ports'");
      if (tables.isEmpty) return false;
      final result = await db.query('custom_ports', where: 'port_name = ?', whereArgs: [portName]);
      return result.isNotEmpty;
    });
  }

  Future<int> addCustomPort(Map<String, dynamic> port) async {
    return await runWithRetry((db) async {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='custom_ports'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE custom_ports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            port_name TEXT NOT NULL UNIQUE,
            latitude REAL,
            longitude REAL,
            is_custom INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      }
      return await db.insert('custom_ports', port);
    });
  }

  Future<int> deleteCustomPort(int id) async {
    return await runWithRetry((db) async {
      return await db.delete('custom_ports', where: 'id = ? AND is_custom = 1', whereArgs: [id]);
    });
  }

  // ============================================================
  // ONE-TIME MIGRATION: Import old route data
  // ============================================================

  Future<void> importOldRouteData() async {
    try {
      // 1. Get the path to the old database file
      final databasesPath = await getDatabasesPath();
      final oldPath = join(databasesPath, 'fishing_voyage.db');

      // 2. Check if the old file exists
      if (!await File(oldPath).exists()) {
        print('ℹ️ No old database found – skipping import.');
        return;
      }

      await runWithRetry((newDb) async {
        print('🔄 Found old database. Importing boat_locations...');

        // 3. Open the old database read‑only
        final oldDb = await openDatabase(oldPath, readOnly: true);

        // 4. Check if we already imported (avoid duplicates)
        final existing = await newDb.query('boat_locations', limit: 1);
        if (existing.isNotEmpty) {
          print('ℹ️ New boat_locations already has data – skipping import.');
          await oldDb.close();
          return;
        }

        // 5. Read all locations from the old table
        final oldLocations = await oldDb.query('boat_locations', orderBy: 'id ASC');
        await oldDb.close();

        if (oldLocations.isEmpty) {
          print('ℹ️ No locations in old database – nothing to import.');
          return;
        }

        print('📦 Found ${oldLocations.length} locations to import.');

        // 6. Create a dummy voyage in the new `voyages` table to link the route
        final voyageId = oldLocations.first['voyage_id'] as int;

        // Check if the voyage already exists in the new db
        final voyageExists = await newDb.query('voyages', where: 'id = ?', whereArgs: [voyageId]);
        if (voyageExists.isEmpty) {
          // Create a dummy voyage with the same id
          await newDb.insert('voyages', {
            'id': voyageId,
            'boat_id': 0, // placeholder
            'boat_number': 'Legacy',
            'fishing_license_no': 'N/A',
            'destination_port': 'N/A',
            'start_date': DateTime.now().toIso8601String(),
            'return_date': DateTime.now().toIso8601String(),
            'fresh_water': '0',
            'diesel': '0',
            'life_jackets': 0,
            'life_boys': 0,
            'communication_devices': 0,
            'emergency_name': 'N/A',
            'emergency_mobile': 'N/A',
            'status': 'completed',
            'created_at': DateTime.now().toIso8601String(),
          });
          print('✅ Created dummy voyage with id $voyageId to link route.');
        }

        // 7. Insert all locations into the new `boat_locations` table
        int importedCount = 0;
        for (var loc in oldLocations) {
          final locCopy = Map<String, dynamic>.from(loc);
          locCopy.remove('id');
          await newDb.insert('boat_locations', locCopy);
          importedCount++;
        }

        print('✅ Successfully imported $importedCount locations into the new database.');
        print('✅ You can now view your old route in the new UI.');
      });
    } catch (e) {
      print('❌ Migration failed: $e');
    }
  }

  // ---- ONE-TIME FIX METHODS ----
  Future<void> fixColumnName() async {
    try {
      await runWithRetry((db) async {
        await db.execute('ALTER TABLE voyages RENAME COLUMN life_buoys TO life_boys');
      });
      debugPrint('✅ One-time column rename successful: life_buoys -> life_boys');
    } catch (e) {
      // Column already renamed or doesn't exist – ignore
      debugPrint('ℹ️ Column rename not needed or already done.');
    }
  }

  void _notifyError(void Function(String)? onError, String msg) {
    if (onError != null) onError(msg);
  }
}
